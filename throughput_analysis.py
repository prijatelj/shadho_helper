"""
Script for analyzing the actual throughput of models in SHADHO. This excludes
all failed runs, because those are not actual model runs that aid in the
hyperparameter search.
"""
import os
from datetime import datetime
from collections import Counter

import argparse
import pandas as pd

from pyrameter import ModelGroup

def count_occurences(model_group, remove_non_success=False):
    # iterate through every models results and count all occurences.
    models_successful_runs = Counter()
    models_failed_runs = Counter()
    models_loss_no_results = Counter()
    models_no_loss_results = Counter()

    for model_id in modelgroup.models:
        models_successful_runs[model_id] = 0
        models_failed_runs[model_id] = 0
        models_loss_no_results[model_id] = 0
        models_no_loss_results[model_id] = 0

        for result in modelgroup.models[model_id].results:
            # result is a Result object, with results dict.
            if result.loss is not None and result.results is not None:
                # Increase successful model run count for this model
                modesl_successful_runs[model_id] += 1
                # could save some information, if necessary. ie. runtime.
                # perhaps avg max cores, max&min cores, avg of core_avg and
                # max_concurrent_processes for every compute class the model
                # runs on. Then informs us of where it should go.
            elif result.loss is not None and result.results is None:
                # chceking for strange cases
                modesl_loss_no_results[model_id] += 1
            elif result.loss is None and result.results is not None:
                # chceking for strange cases
                modesl_no_loss_results[model_id] += 1
            else: # Failures
                modesl_failed_runs[model_id] += 1

    if remove_non_success:
        # return a new modelgroup with only the successes.
        return (
            models_successful_runs,
            models_failed_runs,
            models_loss_no_results,
            models_no_loss_results,
            success_only
        )
    else:
        return (
            models_successful_runs,
            models_failed_runs,
            models_loss_no_results,
            models_no_loss_results
        )

def throughput(modelgroup, timeout):
    """
    Calculates the throughput of successful and failed model runs. Also detects
    strange cases where loss and results are opposites in existing.

    TODO could approx. timeout from earliest start_time and latest finish_time.
    """
    counters = count_occurences(modelgroup)

    # divide occurences by timeout
    return tuple(sum(counter.values()) / timeout for counter in counters)


def parse_args():
    """Defines the arguements of this script."""
    parser = argparse.ArgumentParser(description='Analysis script that summarizes the information contained within SHADHO results.json output.')

    parser.add_argument('input_dir', help='Specify the filepath of the directory containing the result JSON files to analyze.')
    parser.add_argument('timout', help='Specify the timeout for the batch of runs\' results provided.')

    parser.add_argument('-o', '--output_dir', default=None, help='output directory to save the resulting analysis summary files.')

    args = parser.parse_args()

    # enforce conditions of arguements
    if args.timeout <= 0:
        parser.error('timeout must be greater than 0 seconds.')
    if args.output_dir is None:
        # set it to datetime of analysis and create new dir in active diretory
        date_time = str(datetime.now).replace(' ','_')
        args.result_file = 'analysis_output_' + date_time

    # TODO check if provided paths are valid
    #if args.output_results_path invalid, then parser error.

    return args

def summarize_results(modelgroups, timeout):
    # TODO summarize the results in more detail

    #but for not just get throughput
    results_throughput = pd.DataFrame([throughput(modelgroup, timeout) for modelgroup in modelgroups], columns=['success', 'failure', 'loss_no_result', 'no_loss_result'])

    return results_throughput
    #return summarized_results

def load_all_results(input_dir):
    """Loads the modelgroup representations of all results in given directory"""

    # get all json files in given directory
    results = [os.path.join(input_dir,j) for j in os.listdir(input_dir) if isfile(os.path.join(input_dir, j)) and j[-5:] == '.json']
    print('results\n', results)

    # Create the ModelGroup to add structure to the results.
    modelgroups = []
    for result in results:
        modelgroup = ModelGreoup(backend=result)
        modelgroup.load
        modelgroups.append(modelgroup)

    return modelgroups

def save_summary(summarized_results, output_dir):
    """Saves all summary of resutls to output_dir."""

    # ensure the output path exists.
    try:
        os.makedirs(output_dir)
    except:
        pass

    if isinstance(summarized_results, dict):
        # save the dict as a json
    elif isinstance(summarized_results, list) and len(summarized_results) > 0 and isinstance(summarized_results[0], dict):
        # iterate through list of dicts to save them as a json.
    else:
        print('Error: Invalid value type for summarized_results. Did not save.')

if __name__ == '__main__':
    args = parse_args()

    modelgroups = load_all_results(args.input_dir)
    summarized_results = summarize_results(modelgroups, args.timeout)
    #save_summary(summarized_results, args.output_dir)
    # ensure the output path exists.
    try:
        os.makedirs(args.output_dir)
    except:
        pass

    summarized_results.to_csv(args.output_dir)
