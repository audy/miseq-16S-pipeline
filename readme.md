# MISEQ 16S PIPELINE

These are the instructions and source code for analyzing a barcode MiSeq 16S
rRNA. These instructions should take you from raw MISeq reads to an OTU table
that can be used by Phyloseq in R, or any other statistical software.

by Austin G. Davis-Richardson <harekrishna@gmail.com>

### Requirements

1. `usearch`¹, 64-bit, version 6
2. Python 2.7 or greater (but less than 3)
3. `BioPython`, `pandas` and `runstats` (just do `pip install -r requirements.txt`²).
4. `Pandaseq`¹(from [this]() `ref` on GitHub)
  (`brew install pandaseq --HEAD` will work if you're on a mac and have homebrew + homebrew-science installed)

- ¹ Pandaseq and usearch are already installed on the HPC.
- ² May require `sudo`

### Running on HPC

TODO

# Notes

1. Must be using latest version of Pandaseq that supports `-i` flag. See this
  [issue](https://github.com/neufeld/pandaseq/issues/45) for details why.

2. If you have multiple sets of barcodes of different lengths, run the pipeline
   separately for each set and merge the final OTU tables using R.

3. The script that labels reads by barcodes automatically looks for the
   reverse-complement of the barcode sequences provided in `barcodes.csv`.

4. Make sure the barcode reads are the same length as the barcode sequences in
   `barcodes.csv` as sometimes ICBR will add on an extra base. This is also
   important when you have multiple sets of barcodes of different lengths. You
   can optionally trim `N` bases from the beginning of the barcode reads using
   the `--bc-ltrim N` and `--bc-rtrim N` options.

## Steps

1. Assemble pairs with Pandaseq.
2. Label reads by barcode (1 file = 1 sample, original header).
3. USEARCH against GreenGenes.
4. Filter USEARCH output, count taxonomies, generate OTU table.
5. Compute summary stats for pipeline output.

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
