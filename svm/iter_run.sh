#!/usr/bin/bash
# Runs the same experiment in a series for the specified number of iterations.

echo "WARNING! This is not recommended for large amounts of iterations due to that chance of needing to cancel this script. Using Ctrl+C will not terminate the script itself, but the lowest child script, which means safe termination results in using Ctrl+C multiple time but not too many otherwise it will terminate the shadho process cleanup."

# Ensure that proper number of args passed to script
if [ "$#" -lt 2 ] || [ "$#" -gt 9 ]; then
    echo "Error: Script must be passed 2 or 9 args: iterations experiment_id, [output_dir, timeout, model_sort, pyrameter_model_sort, init_model_sort, update_frequency, checkpoint_frequency]"
    exit 1;
fi

for ((i = 1; i <= $1; i++)); do
    echo "Iteration $i:  ${@:2}"
    bash run_shadho_experiment.sh "${@:2}"
done
