# MISEQ 16S PIPELINE

These are the instructions and source code for analyzing a barcode MiSeq 16S
rRNA. These instructions should take you from raw MISeq reads to an OTU table
that can be used by Phyloseq in R, or any other statistical software.

by Austin G. Davis-Richardson

### Requirements

1. usearch, 64-bit, version 8
2. Python 2.7 or greater (but less than 3)
3. BioPython (`pip install BioPython` usually works)
4. Pandaseq (from [this]() `ref` on GitHub)
  (`brew install pandaseq --HEAD` will work if you're on a mac and have homebrew + homebrew-science installed)

# Notes

- Must be using latest version of Pandaseq that supports `-i` flag. See this
  [issue](https://github.com/neufeld/pandaseq/issues/45) for details why.

## Steps

1. Assemble pairs with Pandaseq.
2. Label reads by barcode (1 file = 1 sample, original header).
3. USEARCH against GreenGenes.
4. Count taxonomies, generate OTU table.

## Usage

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

### Label reads by barcode:

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

### Run USEARCH

```bash
usearch \
  -usearch_local labelled.fastq \
  -database greengenes_97.uc.udb \
  -b6out labelled.versus_gg97.txt
```

### Count Taxonomies
