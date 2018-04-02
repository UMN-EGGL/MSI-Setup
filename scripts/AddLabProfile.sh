#!/bin/bash
# Script to set up MSI so that everyone plays along.
# Written by Jack Stanek and Rob Schaefer.
#  

SCRIPT_DIR="/home/mccuem/shared/MSI-Setup"

CONDA_BASE="/home/mccuem/shared/.local/conda"
SHARED_BASE='/home/mccuem/shared/.local'

touch ~/.bashrc

#SCRIPT_PWD="`dirname \"$BASH_SOURCE\"`"    # relative
#PWD="`( cd \"$SCRIPT_PWD\" && pwd )`"      # absolutized and normalized


if [[ $(grep "source $SCRIPT_DIR/mccuem_profile" $HOME/.bashrc | wc -l ) != 1 ]]; then
    echo "source $SCRIPT_DIR/mccuem_profile" >> $HOME/.bashrc
fi

export LAB_PROFILE=''
source $SCRIPT_DIR/mccuem_profile

echo INSTALLATION COMPLETE
