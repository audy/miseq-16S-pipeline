# Tutorial

Instructions for processing a multiplexed MiSeq 16 rRNA sequencing run on the
UF Hipergator.

TODO: VIDEO

## Goals

1. Process raw Illumina sequencing data for a 16S rRNA amplicon sequenced using
   overlapping paired-end, barcode Illumina MiSeq.
2. Understand sequence analysis pipeline.
3. Generate an OTU table.
4. Generate a sample data file.
5. Load data into R using Phyloseq.
6. Perform some basic visualization and statistics:
  - Agglomeration
  - Generating "rank" tables
  - Perform statistical test of differential relative abundance between two
    groups.
  - (there could probably be some more recipes here but the Phyloseq
    documentation does a pretty good job already)

## Prerequisites

- A computer with SSH installed (Macintosh will do).
- An account on the UF Hipergator.
- Basic command-line skills.
- Know how to connect to your Hipergator account.

## Datasets

### Raw Reads

The dataset you will be processing is the raw data from a MiSeq 16S rRNA
sequencing run. These data are raw, paired-end reads with quality scores in
FASTQ format.

There are three files:

- `Undetermined_S0_L001_R1_001.fastq.gz` - 3'-most "left" pair reads
- `Undetermined_S0_L001_I1_001.fastq.gz` - barcode reads
- `Undetermined_S0_L001_R2_001.fastq.gz` - 5'-most "right" pair reads

### Sample Data aka "metadata"

I will show you how to generate this file using Excel.

### Database

For the purposes of this tutorial, I am going to use the GreenGenes v13.8
database. There are some important assumptions made about the format of the
database which I will go over.

## Pipeline

1. Assemble the overlapping paired-end reads using a special version of
   Pandaseq that supports barcoded sequences.
2. Label the reads by barcode using the `bin/label-by-barcode` script. We used
   to split reads into a separate file for each barcode. There are technical
   reasons for why this is bad (hard drives are bad at random access) so now we
   label the reads by barcode.
3. Classify the reads using USEARCh and the GreenGenes database. This will
   generate a bunch of `uc` files that contain (a) the read id, (b) the same id
   (barcode), and the OTU id (reference in GreenGenes).
4. Generate an OTU table using `bin/count-taxonomies`. This is a spreadsheet
   that contains sample IDs (rows) and OTU ids (columns) with read counts as
   the cell value. This file can be easily loaded into Python or R (phyloseq).
