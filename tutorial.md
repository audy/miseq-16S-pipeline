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

### Connecting to the HPC

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

### Working on the HPC

Here are some things to keep in mind when working on the HPC:

- There is a head node and dev nodes
- The head node is for submitting and running small, non-computationally
   intensive commands.
- If you run computationally intensive stuff on the head node, you will slow
   down or crash the HPC for everyone. Type `who` to see who is connected to
   the HPC. These are the people who will be upset with you.
- You can either submit jobs or run an interactive terminal session on a dev
   node.
- To run an interactive session, type `qsub -I` or `ssh dev01`.
- To check if you're in an interactive session, type: `hostname`. It should
  NOT say `gator`.
- All nodes share the same filesystem. After logging into the dev node, you
  will be returned to your home directory `~`, so you will need to `cd` back to
  your scratch directory.

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

### Download scripts

```sh
# on HPC
cd /scratch/lfs/$USER
git clone https://github.com/audy/miseq-16S-pipeline.git

tree miseq-16S-pipeline
```

You should see

```
├── bin                       < -- pipeline scripts
│   ├── count-taxonomies
│   ├── label-by-barcode
│   └── summarize-output
├── data
│   ├── golay-barcodes.csv
│   └── triplett-barcodes.csv < -- our barcodes
├── license.md
├── pipeline.sh               < -- pipeline script
├── prepare.sh                < -- script to setup greengenes database
├── readme.md
├── requirements.txt
├── test                      < -- test data/code
└── tutorial.md               < -- this document
```

### Install Requirements

```bash
# on HPC

# make sure you are running a newer version of Python
# I have tested all of the scripts on Python 2.7.x. Python 3 will not work.
# NOTE: you need to do this every time you log-in to the HPC to run these scripts!
module load python/2.7.8

# install requirements (pandas, runstats, biopython)
# NOTE: you only need to do this once or if you get an error that says
# "runstats not found"
pip install --user -r requirements.txt
```

### Setup GreenGenes Database

```
# on HPC
# from miseq-16S-pipeline directory on scratch
# make sure you are running on a dev node

cat prepare.sh

# inspect contents
# it's really not that complicated

# download and prepare database
./prepare.sh
```

### Run test pipeline

Let's just make sure everything's gonna work, alright?

```
# on HPC, dev node
# from miseq-16S-pipeline directory
test/run.sh
```

# Run Pipeline!

You've finally made it to the pre-game. The real big event is when you analyze
the output of the pipeline.

```
# on HPC, dev node
# from miseq-16S-pipeline directory
cat pipeline.sh

# this is all described in the readme.
```

## Run Pipeline Manually

Now we're going to run the pipeline step by step so we can see what's going on.
This is important because you'll sometimes have to make changes.  Later, we'll
submit the automated version to the HPC queue.


Make sure you are actually running these things on the Dev node or the admins
will get angry and replace your reads with platyplus DNA!

### Assemble Paired-End Reads

```sh
# from miseq-16S-pipeline

# (replace forward_reads, etc... with path to our data)
# (change assembled.fasta to whatever you want the output to be)

pandaseq \
  -f forward_reads.fastq \
  -i barcode_reads.fastq \
  -r reverse_reads.fastq \
  -w assembled.fasta \
  -G log.txt.bz2

# grab some coffee
```

### Label Reads by Barcode

```sh
bin/label-by-barcodes \
  --barcodes data/triplett-barcodes.csv \
  < assembled.fasta \
  > labelled.fasta
```

### Classify Reads with USEARCH

```sh
# classify reads with usearch
usearch \
  -usearch_local labelled.fasta \
  -id 0.97 \
  -query_cov 0.95 \
  -strand plus \
  -uc labelled.uc \
  -db db/97_otus.udb
```

### Generate OTU Table

```bash
bin/count-taxonomies \
  < labelled.uc \
  > labelled.csv
```

### Inspect Results

This script will print some summary statistics for the various steps of the
pipeline.

```bash
bin/summarize-results -d .
```

## Run Pipeline Using HPC Queue

I have created a script which runs all of the pipeline steps and can be
submitted to the HPC queue.

(inspect contents of script)

```bash
qsub -v out_dir=OUTPUT_DIRECTORY,left_reads=LEFT_READS,right_reads=RIGHT_READS,bc_reads=BC_READS pipeline.sh
```

Specify `OUTPUT_DIRECTORY`, etc... with your own values.

### Check Status of HPC job

```
qstat -u $USER
```

- `S`: Submitted and Waiting
- `R`: Running
- `C`: Cancelled/Crashed/Completed


## Download data from SCP

```
# run locally
scp -Cr USERNAME@hipergator.hpc.ufl.edu:/scratch/lfs/USERNAME/output ~/Desktop

# or...
rsync --compress --recursive --progress USERNAME@hipergator.hpc.ufl.edu:/scratch/lfs/USERNAME/output ~/Desktop
```
