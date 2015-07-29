#!/bin/bash

#PBS -q default
#PBS -m abe
#PBS -j oe
#PBS -l pmem=1gb
#PBS -l walltime=10:00:00
#PBS -l nodes=1:ppn=12
#PBS -N miseq-pipeline

set -e

# input files
export left_reads='test/data/reads_R1.fastq'
export bc_reads='test/data/reads_I1.fastq'
export right_reads='test/data/reads_R2.fastq'
export database='gg_13_8_otus/rep_set/97_otus.fasta'
export out_dir='test-out'

# clean previous test run

rm -rf ${out_dir}

sh pipeline.sh

echo "passed!"
