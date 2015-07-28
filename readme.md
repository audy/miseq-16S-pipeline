# MISEQ 16S PIPELINE

These are the instructions and source code for analyzing a barcode MiSeq 16S
rRNA. These instructions should take you from raw MISeq reads to an OTU table
that can be used by Phyloseq in R, or any other statistical software.

by Austin G. Davis-Richardson <harekrishna@gmail.com>

### Requirements

1. usearch, 64-bit, version 8
2. Python 2.7 or greater (but less than 3)
3. BioPython (`pip install BioPython` usually works)
4. Pandaseq (from [this]() `ref` on GitHub)
  (`brew install pandaseq --HEAD` will work if you're on a mac and have homebrew + homebrew-science installed)

All of these tools are installed on the HPC.

### Running on HPC

To run this on the HPC, first run `test/prepare_hpc.sh`. This will load the
appropriate versions of Pandaseq and USEARCH needed to run the analysis.

Just make sure you connect ot a development node before running any of the
analysis steps. The easiest way to do this is `ssh dev01`.

# Notes

1. Must be using latest version of Pandaseq that supports `-i` flag. See this
  [issue](https://github.com/neufeld/pandaseq/issues/45) for details why.

2. If you have multiple sets of barcodes of different lengths, run the pipeline
   separately for each set and merge the final OTU tables using R.

3. The script that labels reads by barcodes automatically looks for the
   reverse-complement of the barcode sequences provided in `barcodes.csv`.

4. Make sure the barcode reads are the same length as the barcode sequences in
   `barcodes.csv` as sometimes ICBR will add on an extra base. This is also
   important when you have multiple sets of barcodes of different lengths.

## Steps

1. Assemble pairs with Pandaseq.
2. Label reads by barcode (1 file = 1 sample, original header).
3. USEARCH against GreenGenes.
4. Count taxonomies, generate OTU table.

## Pipeline Description

### Assemble reads w/ Pandaseq

(note: at this moment, you must be using the latest version of Pandaseq from GitHub)

```bash
pandaseq \
  -f forward_reads.fastq \
  -i barcode_reads.fastq \
  -r reverse_reads.fastq \
  -w assembled.fasta \
  -G log.txt.bz2
```

(pandaseq formats output as fasta by default)

### Label Reads by Barcode

1. Prepare a `barcodes.csv` file (see `data/triplett-barcodes.csv` for an
   example. Note: barcodes must all be the same length. If you sequenced
   multiple sets of barcodes of different length, you will need to run each set
   of barcodes through the entire pipeline separately.
2. Barcode reads will be trimmed to the length of the shortest barcode in your
   `barcodes.csv` file. Sometimes this requires a bit of preprocessing. Call a
   programmer!

Run script

```bash
bin/label-by-barcodes \
  --barcodes data/triplett-barcodes.csv \
  < assembled.fasta \
  > labelled.fasta
```

### Classify Reads with USEARCH

```bash
# make usearch database
usearch \
  -makeudb_usearch db/97_otus.fasta \
  -output db/97_otus.udb

# classify reads with usearch
usearch \
  -usearch_local labelled.fasta \
  -id 0.97 \
  -query_cov 0.95 \
  -strand plus \
  -uc labelled.uc \
  -db db/97_otus.udb
```

### Generate OTU Table

```bash
bin/count-taxonomies \
  < labelled.uc \
  > labelled.csv
```

That's it! The file `labelled.csv` can be then loaded into Phyloseq. You will
also need the taxonomy table `db/97_otu_taxonomy.txt`.

# Load Data into Phyloseq

```S
# you will also need a metadata table
# (todo: make a sample dataset)

meta <- read.csv('metadata.csv')
otus <- read.csv('labelled.csv', header=T, row.names=1)
taxa <- read.csv('db/97_otu_taxonomy.txt')

otus <- otu_table(otus)
taxa <- taxonomy_table(taxa)
meta <- sample_data(meta)

phy <- phyloseq(otus, taxa, meta)

# do some stuff with Phyloseq
```
