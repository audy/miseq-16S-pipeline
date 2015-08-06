# Tutorial

Instructions for processing a multiplexed MiSeq 16 rRNA sequencing run on the
UF Hipergator.

- TODO: VIDEO
- TODO: Slides

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


# Steps

## Open Terminal

1. Go to Finder > Utilities > Terminal

## Connect to HPC

```sh
# connect using secure shell
ssh username@hipergator.hpc.ufl.edu

# you may need to type 'yes' to accept the HPC's key

# type your password and press Enter
# (characters will not display while typing)

# check that you are now connected to the HPC
hostname
# should say gator1.hpc or gator2.hpc

# check out the contents of your scratch directory
# the scratch directory is where files will need to be if you run any
# computationally intensive work on them.

# change to scratch directory
cd /scratch/lfs/$USER
```

## Move data to HPC

I gave you the data on a USB drive because that is how you will receive it from
ICBR. The drive is usually encrypted but there are easy to follow instructions
that come with the drive. The instructions are not always the same so I will
leave that part to ICBR to explain.

Insert the USB drive. Open a new terminal window. This is your local terminal
window. The other terminal window is connected to the HPC. To send data to the
HPC, you will need to type a command into your local terminal window.

```sh
# run locally
scp -Cr /Volumes/USB_DRIVE/miseq-15-Mar-2015 username@hipergator.hpc.ufl.edu:/scratch/lfs/$USER

# wait patiently, should take about 20 minutes
```

OK let's just skip that and move it from our RLTS drive to save time. The
instructions are there. Everything else is the same.

```sh
# run on the HPC
cp -r /rlts/triplett/miseq-15-Mar-2015 /scratch/lfs/$USER
# copy (r = copy a directory) source destination
# this should only take a minute or so
```

Now that we have the data, let's inspect its contents

```sh
# on the hPC

# change to scratch directory
cd /scratch/lfs/$USER

# list contents

tree miseq-15-Mar-2015
```

You should see the following:

```
miseq-march-2015/
├── MS_ETriplett-103906_16S-BT0_2x300V3
│   ├── Undetermined_S0_L001_I1_001.fastq                                  < -- barcode reads
│   ├── Undetermined_S0_L001_R1_001.fastq                                  < -- 5'-most reads
│   └── Undetermined_S0_L001_R2_001.fastq                                  < -- 3'-most reads
├── MS_ETriplett-103906_16S-BT0_2x300V3.Triplett.Illumina.MiSeq.ReadMe.txt < -- readme from ICBR
└── MS_ETriplett-103906_16S-BT0_2x300V3.Triplett.Illumina.MiSeq.sha512     < -- integrity check file
```

## Prepare MiSeq Pipeline

Download scripts

```sh
cd /scratch/lfs/$USER
git clone git@github.com:audy/miseq-16S-pipeline.git
```

Setup GreenGenes Database

```
cd miseq-16S-pipeline
./prepare.sh
```
