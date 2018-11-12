#!/usr/bin/bash

# Ensure that proper number of args passed to script
if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
    echo "Error: Script must be passed 1 or 4 args: experiment_id, [output_dir, duration_of_iteration, scheduler]"
    exit 1;
fi

# Get Date and Time for naming this experiment session
DATE="$(date '+%Y-%m-%d_%H:%M:%S')"

#save the first arg as the experiment identifier
ID=$1

# if third arguement given, then use as output path.
if [ "$#" -ge 2 ]; then
    OUTPUT_DIR=$2;
    # Create the results directory first
    mkdir -p "$OUTPUT_DIR";
else
    OUTPUT_DIR=".";
fi

## Optional arguements in driver.py
# if duration of iterations is given, ow. None
if [ "$#" -ge 3 ]; then
    DURATION=$3;
else
    DURATION="None";
fi

# the id of scheduler to test, if not provided, then assumed none.
if [ "$#" -ge 4 ]; then
    SCHEDULER=$4;
else
    SCHEDULER="None";
fi

# NOTE that this would be sequential, while this could be done in parallel!
# just run them side by side with unique masters names.

# Construct Master Name from parts
MASTER_NAME="$ID-$SCHEDULER-$DATE"
echo "master_name = $MASTER_NAME"

# Create the shadho worker factories to run in the background.
#TODO allow user to specify -w and -W in this script
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=2 --extra-options '-t 120' &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=4 --extra-options '-t 120' &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=8 --extra-options '-t 120' &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=16 --extra-options '-t 120' &

# Create the arguements to run the driver
DRIVER_ARGS="$MASTER_NAME $OUTPUT_DIR/$MASTER_NAME.json"

if [ $DURATION != "None" ]; then
    DRIVER_ARGS="$DRIVER_ARGS -t $DURATION"
fi
if [ $SCHEDULER != "None" ]; then
    DRIVER_ARGS="$DRIVER_ARGS -s $SCHEDULER"
fi

# Run the python driver
python3 driver.py $DRIVER_ARGS 

# kill all factories and workers.
ps aux | grep $1 | grep work_queue | awk '{print $2}' | xargs -L1 kill
ps aux | grep $1 | grep shadho_wq | awk '{print $2}' | xargs -L1 kill

# remove all condor jobs
condor_q $1 | awk '{print $1}' | grep '\.' | xargs -L1 condor_rm
