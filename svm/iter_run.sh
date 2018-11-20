#!/usr/bin/bash
# Runs the same experiment in a series for the specified number of iterations.

# Ensure that proper number of args passed to script
if [ "$#" -lt 1 ] || [ "$#" -gt 5 ]; then
    echo "Error: Script must be passed 1 or 5 args: number_of_iterations experiment_id, [output_dir, duration_of_iteration, scheduler]"
    exit 1;
fi

for ((i = 1; i <= $1; i++)); do
    echo "Iteration $i:  ${@:2}"
    bash run_shadho_experiment.sh "${@:2}"
done
