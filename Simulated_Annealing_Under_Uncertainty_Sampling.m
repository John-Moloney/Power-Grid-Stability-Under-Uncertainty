% Struct that has all relavant data from beta distributions
[mpc,Standard_Deviation] = test_system_10_gen_simulated_annealing_data;

% Number of generators
n = length(mpc.gen_dyn(:,1));

% Number of samples
Number_Of_Samples = 20;

% Number of times simulated annealing under uncertainty algorithm is run
Number_Of_Simulations = 1;

% Initialising arrays that are used to store the optimal objective function
% lambda value and the corresponding optimal beta values
Min_lmax_hetero = zeros(Number_Of_Simulations,1);
Min_Objective_Function = zeros(Number_Of_Simulations,1);
Min_beta_store = zeros(Number_Of_Simulations,n);
Min_beta_mean_store = zeros(Number_Of_Simulations,n);
old_beta_mean_store = zeros(Number_Of_Simulations,n);
old_beta_store = zeros(Number_Of_Simulations,n);

% Initialising Beta_Orig, Beta_Tilde and calculating Beta_Orig
Beta_Orig = zeros(n,1);
Beta_Mean = zeros(n,1);

% Counter that is used for assigning the calculated values at each
% simulation to the 
Counter = 1;

% Calculating an intial lambda value
lmax_hetero = nan();
    [success, ~, results, b2] = compute_stability(mpc, 1);
    
    if success
        lmax_hetero = results.max_lyap;
        
    else
        fprintf('no powerflow\n');
    end
%
old_lmax = lmax_hetero;

l_Difference = zeros(n,1);

Direction_Vector = zeros(n,1);
Squares = zeros(n,1);

% Value used in the cooling schedule and also in the objective function
T = 0.05;

% Parameter in the objective function
Penalty_Term = 1;

Old_Objective_Function = old_lmax + Penalty_Term;

for p = 1:Number_Of_Simulations
    
% Initialising store matrix for lambda max
old_lmax_store = zeros(100000,1);
old_Objective_Function_Store = zeros(100000,1);

% Specifying the standard deviation for calculating the distribution for
% each beta value
Beta_Standard_Deviation = zeros(n,1);
for i = 1:n
    Beta_Standard_Deviation(i) = Standard_Deviation;
end

for i = 1:n
    Beta_Mean(i) = (mpc.gen_dyn(i,3))/(2*mpc.gen_dyn(i,2));
end

% Simulated annealing algorithmn incorporating uncertainty
while T > 1e-8
    
    % Calculating the perturbation to apply to the mean of each beta value
    for i = 1:length(Direction_Vector)
        Direction_Vector(i) = normrnd(0,0.5);
        Squares(i) = (Direction_Vector(i))^2;
    end
    Sum_Of_Squares = sum(Squares);
    Magnitude_Of_Vector = sqrt(Sum_Of_Squares);
    Normalised_Direction_Vector = Direction_Vector./Magnitude_Of_Vector;
	New_Beta_Mean = Beta_Mean + Normalised_Direction_Vector*20*T;
    
    % Sampling the beta distribution for each generator
    lmax_store = zeros(Number_Of_Samples,1);
    for j = 1:Number_Of_Samples
    new_beta = zeros(n,1);
        for i = 1:length(Beta_Mean)
            new_beta(i) = normrnd(New_Beta_Mean(i),Beta_Standard_Deviation(i));
        end
        
        for m = 1:n
            mpc.gen_dyn(m,3) = 2*new_beta(m)*mpc.gen_dyn(m,2);
        end

            new_lmax = nan;
            
            [success, ~, results, b2] = compute_stability(mpc, 1);
    
            if success
                new_lmax = results.max_lyap;
        
            else
                fprintf('  no powerflow\n');
            end
            lmax_store(j) = new_lmax;
    end
    
    % Calculating the penalty term, scaled standard deviation
    % and objective function
    l_Mean = mean(lmax_store);
    l_Difference = zeros(Number_Of_Samples,1);
    for i = 1:Number_Of_Samples
        l_Difference(i) = (lmax_store(i) - l_Mean)^2;
    end
    Standard_Deviation = sqrt(sum(l_Difference)/Number_Of_Samples);

    b = (0.05)/(1.5^T);
    Penalty_Term = (b)*(2*Standard_Deviation)/(sqrt(Number_Of_Samples));

    New_Objective_Function = l_Mean + Penalty_Term;
    
	if  New_Objective_Function < Old_Objective_Function || rand < exp((old_lmax - l_Mean)/T)
		old_beta = new_beta;
		old_lmax = l_Mean;
        Beta_Mean = New_Beta_Mean;
        Old_Objective_Function = New_Objective_Function;
    end
    
    % Assigning the Lyapunov exponent, objective function, mean and calulated beta values
    old_lmax_store(Counter) = old_lmax;
    old_Objective_Function_Store(Counter) = Old_Objective_Function;
    old_beta_mean_store(Counter,:) = Beta_Mean(:,1);
    old_beta_store(Counter,:) = old_beta(:,1);
    
    % Cooling schedule
    T = T*0.98995;
    
    Counter = Counter + 1;
end

end

% Determining the lowest Lyapunov exponent, the optimal objective function
Lowest_lmax_hetero = min(old_lmax_store);
Lowest_objective_function = min(old_Objective_Function_Store);

% Calculate the index/indices for the optimal objective function(s) and the optimal
% beta values
Index = find(old_Objective_Function_Store == min(old_Objective_Function_Store));
Optimal_Beta = old_beta_mean_store(Index,:);