#!/usr/bin/bash

# Ensure that proper number of args passed to script
if [ "$#" -lt 1 ] || [ "$#" -gt 8 ]; then
    echo "Error: Script must be passed 1 through 8 args: experiment_id, [output_dir, timeout, model_sort, pyrameter_model_sort, init_model_sort, update_frequency, checkpoint_frequency]"
    exit 1;
fi

# Load python on CRC if not already loaded.
# TODO may want to make a conditional check, but for now it should work
module add python/3.6.4

# Get Date and Time for naming this experiment session
DATE="$(date '+%Y-%m-%d_%H:%M:%S')"

#save the first arg as the experiment identifier
ID=$1

# create empty args string to be added to as necessary
DRIVER_ARGS=""

# if third arguement given, then use as output path.
if [ "$#" -ge 2 ]; then
    OUTPUT_DIR=$2;
    # Create the results directory first
    mkdir -p "$OUTPUT_DIR";
else
    OUTPUT_DIR="."; # a '.' for current dir because always appeneded with '/'.
fi

## Optional arguements in driver.py
# if duration of iterations is given, ow. None
if [ "$#" -ge 3 ] && [ "$3" != "None" ]; then
    TIMEOUT=$3;
    DRIVER_ARGS="$DRIVER_ARGS -t $TIMEOUT"
else
    TIMEOUT="None";
fi

# the id of scheduler to test, if not provided, then assumed none.
if [ "$#" -ge 4 ] && [ "$4" != "None" ]; then
    MODEL_SORT=$4;
    DRIVER_ARGS="$DRIVER_ARGS -s $MODEL_SORT"
else
    MODEL_SORT="None";
fi

# the id of pyrameter modelgroup scheduler to test, if not provided, then assumed none.
if [ "$#" -ge 5 ] && [ "$5" != "None" ]; then
    PYRAMETER_MODEL_SORT=$5;
    DRIVER_ARGS="$DRIVER_ARGS -p $PYRAMETER_MODEL_SORT"
else
    PYRAMETER_MODEL_SORT="None";
fi

# the id of initial scheduler for first strarting SHADHO, if not provided, then assume its the same as MODEL_SORT.
if [ "$#" -ge 6 ] && [ $6 != $MODEL_SORT ]; then
    INIT=$6;
    DRIVER_ARGS="$DRIVER_ARGS -i $INIT"
else
    INIT=$MODEL_SORT;
fi

# provide update frequency
if [ "$#" -ge 7 ] && [ "$7" -ne 10 ]; then
    UPDATE_FREQUENCY=$7;
    DRIVER_ARGS="$DRIVER_ARGS -u $UPDATE_FREQUENCY"
else
    UPDATE_FREQUENCY=10;
fi

# provide checkpoint frequncy for saving backend as shadho runs.
if [ "$#" -ge 8 ] && [ "$8" -ne 50 ]; then
    CHECKPOINT_FREQUENCY=$8;
    DRIVER_ARGS="$DRIVER_ARGS -c $CHECKPOINT_FREQUENCY"
else
    CHECKPOINT_FREQUENCY=50;
fi

# Construct Master Name from parts
MASTER_NAME="$ID-t-$TIMEOUT-s-$MODEL_SORT-p-$PYRAMETER_MODEL_SORT-i-$INIT-u-$UPDATE_FREQUENCY-$DATE"
echo "master_name = $MASTER_NAME"

# Create the shadho worker factories to run in the background.
#TODO allow user to specify -w and -W in this script
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=2 --tasks-per-worker=1 &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=4 --tasks-per-worker=1 &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=8 --tasks-per-worker=1 &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=16 --tasks-per-worker=1 &

# append the optional arguements
DRIVER_ARGS="$MASTER_NAME $OUTPUT_DIR/$MASTER_NAME.json $DRIVER_ARGS"

# Run the python driver
python3 driver.py $DRIVER_ARGS 

# kill all factories and workers.
ps aux | grep $1 | grep work_queue | awk '{print $2}' | xargs -L1 kill
ps aux | grep $1 | grep shadho_wq | awk '{print $2}' | xargs -L1 kill
