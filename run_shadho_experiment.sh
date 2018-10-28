#!/usr/bin/bash

# Ensure that proper number of args passed to script
if [ "$#" -lt 1 ] || [ "$#" -gt 5 ]; then
    echo "Error: Script must be passed 1 or 4 args: experiment_id, [ scheduler, output_dir, iterations_of_runs, duration_of_iterations ]"
    exit 1;
fi

# Get Date and Time for naming this experiment session
DATE="$(date '+%Y-%m-%d_%H:%M:%S')"

#save the first arg as the experiment identifier
ID=$1

# second arg is the scheduler name to test, if not provided, then assumed none.
if [ "$#" -ge 2 ]; then
    SCHEDULER=$2;
else
    SCHEDULER="None";
fi

# if third arguement given, then use as output path.
if [ "$#" -ge 3 ]; then
    OUTPUT_DIR=$3;
else
    OUTPUT_DIR="None";
fi

# if number of iterations to repeat the experiment is given, ow. None
if [ "$#" -ge 4 ]; then
    ITERATIONS=$4;
else
    ITERATIONS="None";
fi

# if duration of iterations is given, ow. None
if [ "$#" -ge 5 ]; then
    DURATION=$5;
else
    DURATION="None";
fi


# Create the results directory first
if [ ! -d "$OUTPUT_DIR" ]; then
    # create directory
    mkdir -p "$OUTPUT_DIR";
fi

# TODO Repeat runs after specified duration. Unique master name for each.

# Construct Master Name from parts
MASTER_NAME="$ID-$SCHEDULER-$DATE"

# Create the shadho worker factories to run in the background.
#TODO allow user to specif -w and -W in this script
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=2 &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=4 &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=8 &
~/.local/bin/shadho_wq_factory -M $MASTER_NAME -T condor -w 10 -W 20 --cores=16 &

# Run the python driver
python3 svm/driver.py -o "$OUTPUT_DIR/$MASTER_NAME.json" "$MASTER_NAME"

# kill all factories and workers.
ps aux | grep $1 | grep work_queue | awk '{print $2}' | xargs -L1 kill
ps aux | grep $1 | grep shadho_wq | awk '{print $2}' | xargs -L1 kill

# remove all condor jobs
condor_q $1 | awk '{print $1}' | grep '\.' | xargs -L1 condor_rm
