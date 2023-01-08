# Power-Grid-Under-Uncertainty
MATLAB code to accompany "Optimisation of Power Grid Stability Under Uncertainty" is accessible  on [provide link].

This repository contains MATLAB code for running the simulated annealing under uncertainty algorithm using the 'Simulated_Annealing_Under_Uncertainty_Sampling.m' script with the data specified in 'test_system_10_gen_simulated_annealing_data.m'.

The 'Lambda_Distribution.m' script is used to generate lambda distributions and also plots lambda versus quantile values for a specified level of applied noise once a specific data file is specified. The uncertainty that we wish to investigate is specified in the data files as oppposed to the 'Lambda_Distribution.m' script.

These data files include 'test_system_10_gen_beta_equals_data.m' and 'test_system_10_gen_beta_notequals_data.m' which have the single optimal beta value and the optimal beta values respectively when optimised in the absence of uncertainty. There are also the data files 'test_system_10_gen_beta_u_sigma_001_data.m', 'test_system_10_gen_beta_u_sigma_01_data.m' and 'test_system_10_gen_beta_u_sigma_1_data.m' which have the optimal beta values when optimised under uncertainty with an uncertainty level of 0.01, 0.1 and 1 respectively. These data files are adapted from the data provided by [1] with uncertainty included in each parameter. As mentioned in [1], these data files use the case39.m file from the MATPOWER toolbox that is found in [2]. The dynamic parameters include the inertia constant, damping constant and internal reactance of each generator from [3].

[1] F. Molnar, T. Nishikawa, and A. E. Motter, Asymmetry underlies stability in power grids (this paper), GitHub repository: code and data for analyzing converse symmetry breaking in power-grid networks, (2021), https://doi.org/10.5281/zenodo.4437866.

[2] R. D. Zimmerman, C. E. Murillo-Sanchez, and R. J. Thomas, MATPOWER: Steady-state operations, planning, and analysis tools for power systems research and education, IEEE Transactions on Power Systems, 26 (2011), pp. 12-19, https://doi.org/10.1109/tpwrs.2010.2051168.

[3] M. A. Pai, Energy Function Analysis for Power System Stability, Springer US, Boston, MA, 1989.
