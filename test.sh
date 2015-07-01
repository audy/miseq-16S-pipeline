set -e

left_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_R1_001.fastq'
bc_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_I1_001.fastq'
right_reads='MS_ETriplett-103906_16S-BT0_2x300V3/Undetermined_S0_L001_R2_001.fastq'

bin/split-by-barcode \
  --left-reads $left_reads \
  --bc-reads $bc_reads \
  --right-reads $right_reads \
  --barcodes data/triplett-barcodes.csv \
  --output-dir test
