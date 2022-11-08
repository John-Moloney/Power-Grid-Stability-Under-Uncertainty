# Power-Grid-Under-Uncertainty
MATLAB code to accompany "Optimisation of Power Grid Stability Under Uncertainty" is accessible  on [provide link].

This repository contains MATLAB code for running the simulated annealing under uncertainty algorithm which using the 'Simulated_Annealing_Under_Uncertainty_Sampling.m' scrip with the data specified in 'test_system_10_gen_distribution_uncertainty.m'.

The 'Lambda_Distribution_Linear.m' script is used to generate lambda versus quantile distributions for a specified level of uncertainty.

Note that the 'test_system_10_gen_distribution_uncertainty.m' is adapted from the data provided by [1] with uncertainty included in each parameter. As mentioned in [1], this data file uses the case39.m file from the MATPOWER toolbox that is found in [2]. The dynamic parameters including the inertia constant, damping constant and internal reactance of each generator from [3].

[1] Molnar, F., Nishikawa, T. & Motter, A. E. Asymmetry underlies stability in power grids (this paper), GitHub repository: code and data for analyzing converse symmetry breaking in power-grid networks, https://doi.org/10.5281/zenodo.4437866 (2021).

[2] R. D. Zimmerman, C. E. Murillo-Sanchez, and R. J. Thomas, MATPOWER: Steady-state operations, planning, and analysis tools for power systems research and education, IEEE Transactions on Power Systems, 26 (2011), pp. 12-19, https://doi.org/10.1109/tpwrs.2010.2051168.

[3] M. A. Pai, Energy Function Analysis for Power System Stability, Springer US, Boston, MA, 1989.
