#!/bin/bash

function usage() {
    echo "Usage: gen-queue-script.sh DIRECTORY"
    echo "Creates a script which queues a job to freeze a directory."
    echo "After using this script, run the script which is generated."
    echo "This will queue a job on the lab server to upload to S3."
}


function main() {
    if [[ $# -ne 1 ]]
    then
        usage
        exit 1
    fi

    DIR=$@
    SCRIPT_NAME=".${DIR%/}-enqueue.sh"
    cat > $SCRIPT_NAME <<-EOF
#!/bin/bash
#PBS -l walltime=24:00:00,nodes=1:ppn=16,mem=22gb
#PBS -m abe
#PBS -M stane064@umn.edu
#PBS -N freeze
#PBS -q lab
EOF
    echo "freeze.sh $DIR">> $SCRIPT_NAME

    if [[ $? -eq 0 ]]
    then
        echo "Queue script saved to $SCRIPT_NAME."
        echo "Queue job now? [y/N]"
        read ANSWER
        if [[ $ANSWER = "Y" ]] || [[ $ANSWER = "y" ]]
        then
            qsub -q lab $SCRIPT_NAME
            exit 0
        else
            echo "Run 'qsub -q lab $SCRIPT_NAME' to queue the job."
            exit 0
        fi
    else
        echo "Error creating queue script. The generated script may not work properly..."
        exit 1
    fi
}

main $@
