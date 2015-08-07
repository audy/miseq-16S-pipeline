#!/bin/bash

#PBS -q default
#PBS -m abe
#PBS -j oe
#PBS -l pmem=1gb
#PBS -l walltime=10:00:00
#PBS -l nodes=1:ppn=12
#PBS -N miseq-pipeline

# USAGE:

set -e

# will fail if $out_dir already exists (this is a good thing)
mkdir ${out_dir}

# determine number of threads. This is defined by PBS_NP if submitting a job.
# Otherwise, default to 1.
: ${PBS_NP:="1"}

# only run if running on HPC
if [ ${PBS_O_QUEUE} ]; then
  module load pandaseq/20150627
  module load usearch/6.1.544-64
  module load python/2.7.8
  cd ${PBS_O_WORKDIR}
fi

# assemble overlapping, paired-end Illumina HiSeq reads
pandaseq \
  -f $left_reads \
  -i $bc_reads \
  -r $right_reads \
  -G ${out_dir}/log.txt.bz2 \
  -w ${out_dir}/assembled.fasta

# label assembled reads by barcode
bin/label-by-barcode \
  --barcodes data/triplett-barcodes.csv \
  <  ${out_dir}/assembled.fasta \
  > ${out_dir}/labelled.fasta

# classify reads with usearch
usearch \
  -usearch_local ${out_dir}/labelled.fasta \
  -id 0.97 \
  -query_cov 0.95 \
  -strand plus \
  -uc ${out_dir}/labelled.uc \
  -db ${database}

# generate OTU table
bin/count-taxonomies \
  --min-length 250 \
  --min-identity 0.97 \
  < ${out_dir}/labelled.uc \
  > ${out_dir}/labelled.csv

bin/summarize-output --directory ${out_dir} | tee ${out_dir}/stats.txt
