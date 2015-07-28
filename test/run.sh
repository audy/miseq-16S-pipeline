#!/bin/bash

#PBS -q default
#PBS -m abe
#PBS -j oe
#PBS -l pmem=1gb
#PBS -l walltime=10:00:00
#PBS -l nodes=1:ppn=12
#PBS -N miseq-pipeline

# input files
: ${left_reads:='test/data/reads_R1.fastq'}
: ${bc_reads:='test/data/reads_I1.fastq'}
: ${right_reads:='test/data/reads_R2.fastq'}
: ${database:='gg_13_8_otus/rep_set/97_otus.fasta'}

# determine number of threads. This is defined by PBS_NP if submitting a job.
# Otherwise, default to 1.
: ${PBS_NP:="1"}

# only run if running on HPC
if [ ${PBS_O_QUEUE} ]; then
  module load pandaseq/20150627
  module load usearch/6.1.544-64
  cd ${PBS_O_WORKDIR}
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

# classify reads with usearch
usearch \
  -usearch_local labelled.fasta \
  -id 0.97 \
  -query_cov 0.95 \
  -strand plus \
  -uc labelled.uc \
  -db ${database}.udb

# generate OTU table
bin/count-taxonomies \
  < labelled.uc \
  > labelled.csv
