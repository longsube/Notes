!/bin/bash
###############################################################################
#
# listfiles - lists all files in a particular directory
#
###############################################################################

dir=$1

# Check if directory exists first
if [ ! -d $dir ]
then
    echo 'The '$dir' directory has not been created yet.'
    exit 0
fi

# List all the files in the directory
echo '========== Files in the '$1' =========='
ls -l $dir

exit 0

