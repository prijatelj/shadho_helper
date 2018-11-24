#!/usr/bin/env bash

# Use this file to set up the environment on the worker, e.g. load modules,
# edit PATH/other environment variables, activate a python virtual env, etc.

# For this task, activate an environment that has scikit-learn installed.

module add python/3.6.4
mkdir .joblib
export JOBLIB_TEMP_FOLDER=".joblib"
python3 svm.py
rm -rf .joblib
