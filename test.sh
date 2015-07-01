set -x
set -e

left_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_R1_001.fastq'
bc_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_I1_001.fastq'
right_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_R2_001.fastq'

pandaseq \
  -f $left_reads \
  -i $bc_reads \
  -r $right_reads \
  -G log.txt.bz2 \
  > assembled.fasta

bin/label-by-barcode \
  --barcodes data/triplett-barcodes.csv \
  <  assembled.fasta \
  > labelled.fasta

# usearch
