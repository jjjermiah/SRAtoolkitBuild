#!/bin/bash

# This script downloads SRA files from NCBI and uploads them to GCS

# Set up environment variables
# export PATH=$PATH:/home/centos/sratoolkit.2.9.6-1-centos_linux64/bin
# export PATH=$PATH:/home/centos/gsutil
# export PATH=$PATH:/home/centos/gcloud
# export PATH=$PATH:/home/centos/google-cloud-sdk/bin
# export PATH=$PATH:/home/centos/google-cloud-sdk/platform/google_appengine
# export PATH=$PATH:/home/centos/google-cloud-sdk/bin/bootstrapping

# First we check if two arguments were passed to the script (the SRA accession number and the GCS bucket name and path to folder ). If not, we do return an error describing the lack of an argument.
if [ $# -ne 2 ]; then
    echo "Please provide the SRA accession number and the GCS bucket name and path to folder"
    exit 1
fi

# We then check if the SRA accession number is valid. If not, we do return an error describing the lack of an argument.
if [ -z "$1" ]; then
    echo "Please provide the SRA accession number"
    exit 1
fi

# We then check if the GCS bucket name and path to folder is valid. If not, we do return an error describing the lack of an argument.
if [ -z "$2" ]; then
    echo "Please provide the GCS bucket name and path to folder"
    exit 1
fi

# Set variables
SRA=$1
GCS=$2

# Mount the GCS bucket to the instance at /mnt/data
mkdir /mnt/data
gcsfuse $GCS /mnt/data

cd /mnt/data

# Download the SRA file from NCBI to the instance at /mnt/data
prefetch $SRA 

# Convert the SRA file to FASTQ format
# fastq-dump --split-files $SRA


