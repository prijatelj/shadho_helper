"""This example sets up a search over Support Vector Machine kernel
   hyperparameters.
"""
from shadho import Shadho, spaces
import argparse

def parse_args():
    """Defines the arguements of this script."""
    parser = argparse.ArgumentParser(description='Driver for the SHADHO implementation of SVM example.')

    parser.add_argument('master_name', help='Name of the master that controls the SHADHO workers.')
    parser.add_argument('result_file', help='Specify the filename of the result JSON file.')

    parser.add_argument('-t', '--timeout', default=3600, type=float, help='Timeout duration of SHADHO run.')
    parser.add_argument('-u', '--update_frequency', default=10, type=int, help='The frequency at which SHADHO will update the assignment of models to compute classes.')
    parser.add_argument('-c', '--checkpoint_frequency', default=50, type=int, help='The frequency at which SHADHO will save progress to the backend while running.')

    parser.add_argument('-m', '--model_sort', default=None, help='The sorting method to be used for allocating models to SHADHO computation classes.')
    parser.add_argument('-i', '--init_model_sort', default=None, help='The sorting method to be used for allocating models to SHADHO computation classes at the beginning of running SHADHO.')
    parser.add_argument('-p', '--pyrameter_model_sort', default=None, help='The sorting method to be used for ordering models in modelgroups and determing their priority in running relative other models in the same modelgroup.')


    args = parser.parse_args()

    # enforce conditions of arguements
    if args.timeout <= 0:
        parser.error('timeout must be greater than 0 seconds.')
    if args.result_file == '' or args.result_file.lower() == 'none':
        args.result_file = './'
    if args.master_name == '':
        parser.error('must provide a distinct master name')
    # TODO check if provided paths are valid
    #if args.output_results_path invalid, then parser error.

    return args

if __name__ == '__main__':
    args = parse_args()

    # Domains can be stored as variables and used more than once in the event
    # that the domain is used multilpe times.
    C = spaces.log2_uniform(-5, 15)
    gamma = spaces.log10_uniform(-3, 3)
    coef0 = spaces.uniform(-1000, 1000)

    # The search space in this case is hierarchical with mutually exclusive
    # subspaces for each SVM kernel. The 'exclusive' tag instructs SHADHO to
    # select one of the subspaces from among 'linear', 'rbf', 'sigmoid', and
    # 'poly' at a time and only generate hyperprameters for that subspace.
    space = {
        'exclusive': True,
        'linear': {
            'kernel': 'linear',  # add the kernel name for convenience
            'C': C
        },
        'rbf': {
            'kernel': 'rbf',  # add the kernel name for convenience
            'C': C,
            'gamma': gamma
        },
        'sigmoid': {
            'kernel': 'sigmoid',  # add the kernel name for convenience
            'C': C,
            'gamma': gamma,
            'coef0': coef0
        },
        'poly': {
            'kernel': 'poly',  # add the kernel name for convenience
            'C': C,
            'gamma': gamma,
            'coef0': coef0,
            'degree': spaces.randint(2, 15)
        },
    }

    # Set up the SHADHO driver like usual
    if args.pyrameter_model_sort is 'uniform_random':
        use_complexity=False
        use_priority=False
    else:
        use_complexity=True
        use_priority=True

    opt = Shadho('bash svm_task.sh', space,
        use_complexity=use_complexity,
        use_priority=use_priority,
        timeout=args.timeout,
        backend=args.result_file,
        update_frequency=args.update_frequency,
        checkpoint_frequency=args.checkpoint_frequency,
        model_sort=agrs.model_sort,
        init_model_sort=args.init_model_sort,
        pyrameter_model_sort=args.pyrameter_model_sort,
    )
    #opt = Shadho('bash svm_task.sh', space, timeout=args.timeout, backend=args.result_file)
    # TODO implement the frequency and model sort arguements throughout pyrameter and shadho
    opt.config.workqueue.name = args.master_name
    opt.config.workqueue.port = 0

    # Add the task files to the optimizer
    opt.add_input_file('svm_task.sh')
    opt.add_input_file('svm.py')
    opt.add_input_file('mnist.npz')

    # We can divide the work over different compute classes, or sets of workers
    # with commmon hardware resources, if such resources are available. SHADHO
    # will attempt to divide work across hardware in a way that balances the
    # search.
    # For example, in a cluster with 20 16-core, 25 8-core, and 50 4-core
    # nodes, we can specify:
    opt.add_compute_class('16-core', 'cores', 16, max_tasks=20)
    opt.add_compute_class('8-core', 'cores', 8, max_tasks=20)
    opt.add_compute_class('4-core', 'cores', 4, max_tasks=20)
    #opt.add_compute_class('2-core', 'cores', 2, max_tasks=20)

    opt.run()
