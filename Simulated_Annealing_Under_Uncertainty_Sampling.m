% Loading relevant information
mpc = test_system_10_gen_under_uncertainty;
stress = 1.0;


% Number of generators
n = 10;

% Number of times simulated annealing is run
Number_Of_Simulations = 1;
Min_lmax_hetero = zeros(Number_Of_Simulations,1);
Min_Objective_Function = zeros(Number_Of_Simulations,1);
Min_beta_store = zeros(Number_Of_Simulations,n);
Min_beta_mean_store = zeros(Number_Of_Simulations,n);
old_beta_mean_store = zeros(Number_Of_Simulations,n);
old_beta_store = zeros(Number_Of_Simulations,n);

% Initialising Beta_Orig, Beta_Tilde and calculating Beta_Orig
Beta_Tilde = zeros(n,1);
Beta_Orig = zeros(n,1);
for i = 1:n
Beta_Orig(i) = (mpc.gen_dyn(i,3))/(2*mpc.gen_dyn(i,2));
end

% Testing whether I have all the functions necessary
cap = 1.0;

% Calculating the maximum lambda values for original and optimal beta
% values
lmax = nan(size(stress));
lmax2 = nan(size(stress));
for k = 1 : length(stress)
    s = stress(k);
    fprintf('Computing stress = %f\n', s);
    [success, ~, results, b2] = compute_stability(mpc, cap * s);
% [success, ~, results] = compute_stability(mpc, cap * s);
%     
    if success
        lmax(k) = results.max_lyap;
        lmax2(k) = results.max_lyap2;
        
        if isnan(lmax2(k))
            if ~results.is_alpha_real
                fprintf('  some alpha are complex\n');
                fprintf('  max imaginary part: %f\n', results.max_abs_imag_ev_P);
            end
            fprintf('  alpha_2 = %f + %fi\n', real(results.alpha2), imag(results.alpha2));
        end
    else
        fprintf('  no powerflow\n');
    end
    
end

% Assigning Beta_Tilde
for i = 1:n
Beta_Tilde(i) = b2(i);
end

% Plot it
plot(stress, lmax, '*-')
xlabel('power demand multiplier','interpreter', 'none')
ylabel('lmax','interpreter', 'none')
hold on
plot(stress, lmax2, 'x-')
grid

% Counter for storing lambda values
Counter = 1;

% Initialising vectors used to determine a random point on a hypersurface
% using formula from https://mathworld.wolfram.com/HyperspherePointPicking.html
Direction_Vector = zeros(n,1);
Squares = zeros(n,1);
% Normalised_Direction_Vector = zeros(n,1);
for i = 1:length(Direction_Vector)
    Direction_Vector(i) = unifrnd(-1,1);
    Squares(i) = (Direction_Vector(i))^2;
end


% Normalising direction vector
Sum_Of_Squares = sum(Squares);
Magnitude_Of_Vector = sqrt(Sum_Of_Squares);

% Direction Vectors
Normalised_Direction_Vector = Direction_Vector./Magnitude_Of_Vector;

% Specifying the original beta mean
Beta_Mean = Beta_Orig;

% Specifying the standard deviation for calculating the distribution for
% each beta value
Standard_Deviation = 1;
Beta_Standard_Deviation = [Standard_Deviation, Standard_Deviation, Standard_Deviation, Standard_Deviation, Standard_Deviation,...
    Standard_Deviation, Standard_Deviation, Standard_Deviation, Standard_Deviation, Standard_Deviation];

old_beta = zeros(n,1);
Number_Of_Samples = 5;
for i = 1:length(Beta_Mean)
    old_beta(i) = normrnd(Beta_Mean(i),Beta_Standard_Deviation(i));
end

lmax_hetero = nan(size(stress));
for k = 1 : length(stress)
    s = stress(k);
    fprintf('Computing stress = %f\n', s);
    [success, ~, results, b2] = compute_stability(mpc, cap * s);
    
    if success
        lmax_hetero(k) = results.max_lyap;
        
    else
        fprintf('  no powerflow\n');
    end
    
end
%
old_lmax = lmax_hetero;

% Calculating the objective function
% Calculating the penalty tern
% Calculating the scaled standard deviation
l_Difference = zeros(n,1);
% for i = 1:n
%     Beta_Difference(i) = (old_beta(i) - Beta_Mean(i))^2;
% end
% Standard_Deviation = sqrt(sum(Beta_Difference)/n);

 T = 0.05;

%  b = (0.05)/(1.5^T);
% Penalty_Term = (b)*(2*Standard_Deviation)/(sqrt(n));
Penalty_Term = 1;

Old_Objective_Function = old_lmax + Penalty_Term;

for p = 1:Number_Of_Simulations
    
% Initialising store matrix for lambda max
old_lmax_store = zeros(100000,1);
old_Objective_Function_Store = zeros(100000,1);

while T > 1e-8
    
    for i = 1:length(Direction_Vector)
        Direction_Vector(i) = unifrnd(-1,1);
        Squares(i) = (Direction_Vector(i))^2;
    end
    Sum_Of_Squares = sum(Squares);
    Magnitude_Of_Vector = sqrt(Sum_Of_Squares);
    Normalised_Direction_Vector = Direction_Vector./Magnitude_Of_Vector;
	New_Beta_Mean = Beta_Mean + Normalised_Direction_Vector*20*T;
    lmax_store = zeros(Number_Of_Samples,1);
    for j = 1:Number_Of_Samples
    new_beta = zeros(n,1);
        for i = 1:length(Beta_Mean)
            new_beta(i) = normrnd(New_Beta_Mean(i),Beta_Standard_Deviation(i));
        end
        
        for k = 1:n
            mpc.gen_dyn(k,3) = 2*new_beta(k)*mpc.gen_dyn(k,2);
        end

            new_lmax = nan(size(stress));
        for k = 1 : length(stress)
            s = stress(k);
            [success, ~, results, b2] = compute_stability(mpc, cap * s);
    
            if success
                new_lmax(k) = results.max_lyap;
        
            else
                fprintf('  no powerflow\n');
            end
            lmax_store(j) = new_lmax ;
        end
    end
    
% Calculating the objective function
% Calculating the penalty term
% Calculating the scaled standard deviation
    l_Mean = mean(lmax_store);
    l_Difference = zeros(Number_Of_Samples,1);
    for i = 1:Number_Of_Samples
        l_Difference(i) = (lmax_store(i) - l_Mean)^2;
    end
    Standard_Deviation = sqrt(sum(l_Difference)/Number_Of_Samples);

    b = (0.05)/(1.5^T);
    Penalty_Term = (b)*(2*Standard_Deviation)/(sqrt(Number_Of_Samples));

    New_Objective_Function = l_Mean + Penalty_Term;
    
% 	new_lmax = calculate_lmax(new_beta);
	if  New_Objective_Function < Old_Objective_Function || rand < exp((old_lmax - l_Mean)/T)
		old_beta = new_beta;
		old_lmax = l_Mean;
        Beta_Mean = New_Beta_Mean;
        Old_Objective_Function = New_Objective_Function;
    end
    old_lmax_store(Counter) = old_lmax;
    old_Objective_Function_Store(Counter) = Old_Objective_Function;
    old_beta_mean_store(Counter,:) = Beta_Mean(:,1);
    old_beta_store(Counter,:) = old_beta(:,1);
% 	T = T * 0.99995;
    T = T*0.98995;
    
    Counter = Counter + 1;
end

% Min_beta_store(p,:) = old_beta_store;
% Min_beta_mean_store(p,:) = old_beta_mean_store;

end

Lowest_lmax_hetero = min(old_lmax_store);
Lowest_objective_function = min(old_Objective_Function_Store);

%%
Index = find(old_Objective_Function_Store == min(old_Objective_Function_Store));
Optimal_Beta = old_beta_mean_store(Index,:);