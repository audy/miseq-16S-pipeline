#!/bin/bash

# input files
: ${left_reads:='test/data/reads_R1.fastq'}
: ${bc_reads:='test/data/reads_I1.fastq'}
: ${right_reads:='test/data/reads_R2.fastq'}
: ${database:='gg_13_8_otus/rep_set/97_otus.fasta'}

# determine number of threads. This is defined by PBS_NP if submitting a job.
# Otherwise, default to 1.
: ${PBS_NP:="1"}

# check if running on UF HPC and load modules
if [ ${PBS_O_QUEUE} ]; then
  module load pandaseq/20150627
  module load usearch/6.1.544-64
fi

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
if [ ! -e "${database}.udb" ]; then
  usearch \
    -makeudb_usearch ${database} \
    -output ${database}.udb
fi

# classify reads with usearch
usearch \
  -usearch_local labelled.fasta \
  -id 0.97 \
  -query_cov 0.95 \
  -strand plus \
  -uc labelled.uc \
  -db ${database}.udb \
  -threads ${PBS_NP}

# generate OTU table
bin/count-taxonomies \
  < labelled.uc \
  > labelled.csv
