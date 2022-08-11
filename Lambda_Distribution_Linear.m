% Loading relevant information
% mpc = test_system_10_gen;

% Number of times simulated annealing is run
Number_Of_Simulations = 10000;
lmax_Store = zeros(Number_Of_Simulations,1);
%% Beginning the number of simulations
for j = 1:Number_Of_Simulations

mpc = test_system_10_gen_distribution;
% mpc = test_system_10_gen_distribution_uncertainty;

stress = 1.0;

% Number of generators
n = 10;

% Initialising Beta_Orig, Beta_Tilde and calculating Beta_Orig
Beta_Tilde = zeros(n,1);
Beta_Orig = zeros(n,1);
for i = 1:n
Beta_Orig(i) = (mpc.gen_dyn(i,3))/(2*mpc.gen_dyn(i,2));
end

% Testing whether I have all the functions necessary
cap = 1.0;


%make up some stress levels for plotting
%stress = 0 : 0.05 : 1.8;

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

lmax_Store(j) = lmax;

end

% Run some statistical tests
Lambda_Quantile_Store = zeros(9,1);
Quantile_Store = zeros(9,1);
Sorted_lmax_Store = sort(lmax_Store);
% Quantile = 90;
counter = 1;
for Quantile = 10:10:90
    Quantile_Store(counter) = Quantile;
    Percentage = Quantile/100;
    Lambda_Quantile_Index = (Percentage*Number_Of_Simulations) + 1;
    Lambda_Quantile_Number = Sorted_lmax_Store(Lambda_Quantile_Index);
    Lambda_Homogeneous_Quantile_Store(counter) = Lambda_Quantile_Number;
    Lambda_Heterogeneous_Quantile_Store(counter) = Lambda_Quantile_Number;
    counter = counter + 1;
end

% Plot the histogram
figure;
histogram(lmax_Store)
legend('Heterogeneous Beta standard deviation = 1')

% Plot the quantile versus lambda values and a scatter plot
figure;
plot(Quantile_Store,Lambda_Homogeneous_Quantile_Store);
hold on
plot(Quantile_Store,Lambda_Heterogeneous_Quantile_Store);
xlabel('Quantile')
ylabel('\lambda')
legend('Homogeneous','Heterogeneous')

figure;
scatter(Quantile_Store,Lambda_Homogeneous_Quantile_Store);
hold on
scatter(Quantile_Store,Lambda_Heterogeneous_Quantile_Store);
xlabel('Quantile')
ylabel('\lambda')
legend('Homogeneous','Heterogeneous')