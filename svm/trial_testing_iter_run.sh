#!/usr/bin/bash
# Runs the same experiment in a series for the specified number of iterations.

# This is meant for running a testing trial as done in shadho paper. The method
# used in there was to run each scheduling method immediately after one another
# in order to better overcome the network interference or traffic/usage of the
# distributed machines. This testing_trial method is the ideal way to do this,
# unless it is possible to test each method in parallel, assuming they do not
# interfere with each other.

# so the issue this is trying to solve is that of netwrk interference and
# machine usage.

# NOTE, SHADHO paper for optimizing the svm on mnist ran each optimization task for 1 hour (per scheduling method compared). They also ran 48 trials. This means that 48 trials * 1hr * Number of scheduling methods tested. So 48hrs per scheduling method tested.

# Ensure that proper number of args passed to script
if [ "$#" -lt 2 ] || [ "$#" -gt 9 ]; then
    echo "Error: Script must be passed 2 or 9 args: iterations experiment_id, [output_dir, timeout, model_sort, pyrameter_model_sort, init_model_sort, update_frequency, checkpoint_frequency]"
    exit 1;
fi

# before running every scheduling method, the proper pyrameter and shadho versions must be loaded in the case that they are different

for ((i = 1; i <= $1; i++)); do
    echo "Iteration $i:  ${@:2}"
    # run vanilla shadho
    # run our version of shadho but with randomized scheduling ontop of the complexity and priority
    # other scheduling methods ...

    # run derek dynamic scheduler 1
    # TODO the below will not work, it depends on a single set of args, and those are meant for one specific shadho run with specified scheduler, so need to hardcode the args in this test script.
    cd ../../pyrameter
    git checkout master
    python3 setup.py install --user
    cd ../shadho
    git checkout master
    python3 setup.py install --user
    cd ../shadho_helper/svm
    bash run_shadho_experiment.sh "${@:2}"
done
