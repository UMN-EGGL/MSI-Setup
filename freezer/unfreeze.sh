#!/bin/bash
#PBS -l walltime=24:00:00,nodes=1:ppn=16,mem=22gb
#PBS -m abe
#PBS -M stane064@umn.edu
#PBS -N freeze
#PBS -q lab

CONFIG_PATH="/home/mccuem/shared/.local/.s3cfg"

unalias s3cmd 2> /dev/null
source ~/.bashrc
# activate the correct s3cmd
source /home/mccuem/shared/.local/conda/bin/activate BotBot 1> /dev/null

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
        exit 1
    else
        PROJECT_NAME=$@
    fi

    ARCHIVE_NAME="$PROJECT_NAME.tar.xz"
    S3_ARCHIVE_PATH="s3://mccuelab/$USER/$ARCHIVE_NAME"
    s3cmd --config $CONFIG_PATH get $S3_ARCHIVE_PATH
    tar xJvpf ./$ARCHIVE_NAME
    if [[ $? -ne 0 ]]
    then
        echo "Error decompressing project archive..."
        echo "Project archive is stored at $ARCHIVE_NAME..."
        exit 1
    else
        rm $ARCHIVE_NAME
    fi
}

main $@
