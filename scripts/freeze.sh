#!/bin/bash
#PBS -l walltime=48:00:00,nodes=1:ppn=16,mem=22gb
#PBS -m abe
#PBS -N freeze
#PBS -q lab

CONFIG_PATH="/home/mccuem/shared/.local/.s3cfg"
THREADS=15 # Number of compression threads.
FREEZEBUCKET='mccue-lab'

unalias s3cmd 2> /dev/null
source ~/.bashrc
# activate the correct s3cmd
source /home/mccuem/shared/.local/conda/bin/deactivate
source /home/mccuem/shared/.local/conda/bin/activate s3cmd 2> /dev/null

function usage() {
    echo "How to to use the freeze command:"
    echo "Syntax: % freeze DIRECTORY_NAME"
    echo "This command will archive, compress and upload the contents of"
    echo "DIRECTORY_NAME to secondary storage."
}

function timelog() {
    echo "`date`: $@"
}

function check-xz-version() {
    XZ_VERSION="$(xz --version | head -n 1 | sed -n 's/.*\([0-9]\.[0-9]\.[0-9]\)$/\1/p')"
    REQUIRED_XZ_VERSION="5.2.3"
    LOWER_VERSION=$(echo "$REQUIRED_XZ_VERSION,$XZ_VERSION" | tr ',' '\n' | sort -V | head -n 1)
    if [[ "$LOWER_VERSION" != "$REQUIRED_XZ_VERSION" ]]
    then
        return 1
    else
        return 0
    fi
}

function main() {
    # Start by checking the xz compression version. We want
    # multithreading!
    XZ_CORRECT_VERSION=$(check-xz-version)
    if [[ $XZ_CORRECT_VERSION -eq 1 ]]
    then
        timelog "xz out of date..."
        timelog "($REQUIRED_XZ_VERSION is required, $XZ_VERSION is installed...)"
        exit 1
    fi

    # Parse command line arguments
    if [[ $# -ne 1 ]]
    then
        usage
        exit 1
    else
        DIR=$@
        if [[ ! -e $DIR ]]
        then
            echo "$DIR does not exist..."
            exit 1
        fi
    fi

    # Check available disk space
    timelog "Computing necessary disk space..."
    DIR_SIZE=`du -s $DIR | awk '{print $1;}'`
    AVAILABLE_SPACE=$(($(stat -f --format="%a*%S" .)))
    # 3 * directory size gives decent amount of clearance
    NEEDED_SPACE=$((DIR_SIZE * 3))

    # Check if we have enough disk space
    if [[ $NEEDED_SPACE -ge $AVAILABLE_SPACE ]]
    then
        timelog "Available disk space is insufficient."
        timelog "($NEEDED_SPACE required, $AVAILABLE_SPACE available)"
        exit 1
    else
        timelog "Sufficient disk space found."
    fi

    # We have enough space!
    BASENAME="$(basename $DIR)"
    ARCHIVE_NAME="$BASENAME.tar"
    COMPRESSED_NAME="$ARCHIVE_NAME.xz"
    if [[ -e $ARCHIVE_NAME ]]
    then
        timelog "Found tar archive $ARCHIVE_NAME..."
    else
        timelog "Creating tar archive..."
        tar cpW -C $DIR/.. $BASENAME -f $ARCHIVE_NAME
        if [[ $? -ne 0 ]]
        then
            timelog "Error creating tar archive!"
            exit 1
        else
            timelog "Tar archive created successfully."
        fi
    fi

    timelog "Beginning compression..."
    rm $COMPRESSED_NAME 2> /dev/null
    xz -z -e -T $THREADS $ARCHIVE_NAME
    xz -t $COMPRESSED_NAME
    if [[ $? -ne 0 ]]
    then
        timelog "Error creating compressed archive!"
        exit 1
    else
        timelog "Compression completed successfully."
    fi

    # Upload to S3
    timelog "Beginning upload to S3..."
    PROJ_OWNER=`stat -c %U $DIR`
    s3cmd --config $CONFIG_PATH -r put $COMPRESSED_NAME s3://$FREEZEBUCKET/$PROJ_OWNER/ > /dev/null\
          && rm $COMPRESSED_NAME
    if [[ $? -ne 0 ]]
    then
        timelog "Error uploading compressed archive to S3..."
        timelog "Compressed intermediate archive preserved at $ARCHIVE_NAME..."
        exit 1
    else
        timelog "Upload successful."
    fi
}

# Run the script
main $@
