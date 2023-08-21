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

# First we check if an argument was passed to the script. if so, we use it as the SRA accession number. If not, we do return an error describing the lack of an argument.
if [ $# -eq 0 ]; then
    echo "No arguments provided. Please provide an SRA accession number."
    exit 1
fi

# Set up variables
SRA=$1


