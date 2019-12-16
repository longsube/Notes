#!/bin/bash
###############################################################################
#
# count files - returns the number of files in a particular directory
#
###############################################################################

dir=$1

# Check if directory exists first
if [ ! -d $dir ]
then
    echo 'The '$dir' has not been created yet.'
    exit 0
fi

# Get the number of files in the directory.
number_of_files=$(ls $dir -1 | wc -l)

# Display a nice warning if there's no files and exit the program.
if [ $number_of_files -eq 0 ]
then
    echo 'There is no files in '$1'.'
    exit 0
fi

# Display a number of files in directory
echo 'Number of files in '$1': '$number_of_files

exit 0
