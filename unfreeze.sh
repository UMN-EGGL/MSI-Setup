e#!/bin/bash -l
#PBS -l walltime=24:00:00,nodes=1:ppn=16,mem=22gb
#PBS -m abe
#PBS -M stane064@umn.edu
#PBS -N freeze
#PBS -q lab

unalias s3cmd
source ~/.bashrc
# activate the correct s3cmd
source /home/mccuem/shared/.local/conda/bin/activate s3cmd

function usage() {
    echo "Usage: unfreeze PROJECT-NAME"
    echo "Unfreezes a project from S3."
}

function list() {
    s3cmd ls s3://mccuelab/$USER/ |\
        sed -e 's/^[ \t]*DIR[ \t]*s3:\/\/mccuelab\/kempera\/\(.*\)\/$/\1/'
}

function main() {
    # Parse command line args
    if [[ $# -ne 1 ]]
    then
        usage
    else
        PROJECT_NAME=$@
    fi

    ARCHIVE_NAME="$PROJECT_NAME.tar.xz"
    S3_ARCHIVE_PATH="s3://mccuelab/$USER/$ARCHIVE_NAME"
    s3cmd get $S3_ARCHIVE_PATH
    tar xJvpf ./$ARCHIVE_NAME
    rm $ARCHIVE_NAME
}

main $@
