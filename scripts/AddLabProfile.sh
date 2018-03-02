#!/bin/bash
# Script to set up MSI so that everyone plays along.
# Written by Jack Stanek and Rob Schaefer.

#  
CONDA_BASE="/home/mccuem/shared/.local/conda"
SHARED_BASE='/home/mccuem/shared/.local'

touch ~/.bashrc

PWD="`dirname \"$BASH_SOURCE\"`"    # relative
PWD="`( cd \"$PWD\" && pwd )`"      # absolutized and normalized

echo "Currently in $PWD"

if [[ $(grep "source $PWD/mccuem_profile" $HOME/.bashrc | wc -l ) != 1 ]]; then
    echo "source $PWD/mccuem_profile" >> $HOME/.bashrc
fi

source $PWD/mccuem_profile

echo INSTALLATION COMPLETE
