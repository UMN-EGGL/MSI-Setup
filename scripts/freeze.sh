#!/bin/bash
#PBS -l walltime=48:00:00,nodes=1:ppn=16,mem=22gb
#PBS -m abe
#PBS -N freeze
#PBS -q lab-long

CONFIG_PATH="/home/mccuem/shared/.local/.s3cfg"
THREADS=15 # Number of compression threads.

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

function main() {
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
    echo "Computing necessary disk space..."
    DIR_SIZE=`du -s $DIR | awk '{print $1;}'`
    AVAILABLE_SPACE=$(($(stat -f --format="%a*%S" .)))
    # 3 * directory size gives decent amount of clearance
    NEEDED_SPACE=$((DIR_SIZE * 3))

    # Check if we have enough disk space
    if [[ $NEEDED_SPACE -ge $AVAILABLE_SPACE ]]
    then
        echo "Available disk space is insufficient."
        echo "($NEEDED_SPACE required, $AVAILABLE_SPACE available)"
        exit 1
    else
        echo "Sufficient disk space found."
    fi

    # We have enough space!
    BASENAME="$(basename $DIR)"
    ARCHIVE_NAME="$BASENAME.tar"
    COMPRESSED_NAME="$ARCHIVE_NAME.xz"
    if [[ -e $ARCHIVE_NAME ]]
    then
        echo "Found tar archive $ARCHIVE_NAME..."
    else
        echo "Creating tar archive..."
        tar cpW -C $DIR/.. $BASENAME -f $ARCHIVE_NAME
        if [[ $? -ne 0 ]]
        then
            echo "Error creating tar archive!"
            exit 1
        else
            echo "Tar archive created successfully."
        fi
    fi

    echo "Beginning compression..."
    rm $COMPRESSED_NAME 2> /dev/null
    xz -z -e -T $THREADS $ARCHIVE_NAME
    xz -t $COMPRESSED_NAME
    if [[ $? -ne 0 ]]
    then
        echo "Error creating compressed archive!"
        exit 1
    else
        echo "Compression completed successfully."
    fi

    # Upload to S3
    echo "Beginning upload to Amazon S3..."
    PROJ_OWNER=`stat -c %U $DIR`
    s3cmd --config $CONFIG_PATH -r put $COMPRESSED_NAME s3://mccuelab/$PROJ_OWNER/ > /dev/null\
          && rm $COMPRESSED_NAME
    if [[ $? -ne 0 ]]
    then
        echo "Error uploading compressed archive to S3..."
        echo "Compressed intermediate archive preserved at $ARCHIVE_NAME..."
        exit 1
    else
        echo "Upload successful."
    fi
}

# Run the script
main $@