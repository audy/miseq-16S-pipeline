#!/bin/bash
set -x
set -e

left_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_R1_001.fastq'
bc_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_I1_001.fastq'
right_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_R2_001.fastq'

# assemble overlapping, paired-end Illumina HiSeq reads
pandaseq \
  -f $left_reads \
  -i $bc_reads \
  -r $right_reads \
  -G log.txt.bz2 \
  > assembled.fasta

# label assembled reads by barcode
bin/label-by-barcode \
  --barcodes data/triplett-barcodes.csv \
  <  assembled.fasta \
  > labelled.fasta

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

# generate OTU table
