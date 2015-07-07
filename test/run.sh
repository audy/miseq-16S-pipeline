#!/bin/bash
set -x
set -e

left_reads='test/data/reads_R1.fastq'
bc_reads='test/data/reads_I1.fastq'
right_reads='test/data/reads_R2.fastq'

# TODO: download greengenes + usearch

# assemble overlapping, paired-end Illumina HiSeq reads
pandaseq \
  -f $left_reads \
  -i $bc_reads \
  -r $right_reads \
  -G log.txt.bz2 \
  -w assembled.fasta

# label assembled reads by barcode
bin/label-by-barcode \
  --barcodes data/triplett-barcodes.csv \
  <  assembled.fasta \
  > labelled.fasta

# make usearch database
#usearch \
#  -makeudb_usearch db/97_otus.fasta \
#  -output db/97_otus.udb

# classify reads with usearch
usearch \
  -usearch_local labelled.fasta \
  -id 0.97 \
  -query_cov 0.95 \
  -strand plus \
  -uc labelled.uc \
  -db db/97_otus.udb

# generate OTU table
bin/count-taxonomies \
  < labelled.uc \
  > labelled.csv

# TODO: test phyloseq import
