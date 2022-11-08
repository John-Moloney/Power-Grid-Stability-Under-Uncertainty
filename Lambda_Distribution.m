% Number of times the test is run
Number_Of_Simulations = 10000;

% Array that stores the lambda values from each test
lmax_Store = zeros(Number_Of_Simulations,1);

% Loop that runs the specified number of simulations
for j = 1:Number_Of_Simulations

% Calling the struct that includes the data for this specific simulation
mpc = test_system_10_gen_distribution_uncertainty;

cap = 1.0;

% Number of generators
n = length(mpc.gen_dyn(:,1));

% Initialising Beta_Orig, Beta_Tilde and calculating Beta_Orig
Beta_Tilde = zeros(n,1);
Beta_Orig = zeros(n,1);
for i = 1:n
Beta_Orig(i) = (mpc.gen_dyn(i,3))/(2*mpc.gen_dyn(i,2));
end

% Calculating the maximum lambda values for original and optimal beta
% values
lmax = nan;
lmax2 = nan;
    [success, ~, results, b2] = compute_stability(mpc, 1);
%     
    if success
        lmax = results.max_lyap;
        lmax2 = results.max_lyap2;
        
        if isnan(lmax2)
            if ~results.is_alpha_real
                fprintf('  some alpha are complex\n');
                fprintf('  max imaginary part: %f\n', results.max_abs_imag_ev_P);
            end
            fprintf('  alpha_2 = %f + %fi\n', real(results.alpha2), imag(results.alpha2));
        end
    else
        fprintf('  no powerflow\n');
    end

    % Assigning Beta_Tilde
    for i = 1:n
        Beta_Tilde(i) = b2(i);
    end

    lmax_Store(j) = lmax;

end

% Run some statistical tests

% Calling function that generates a histogram of the lambda values
Histogram(lmax_Store)

% Calling function that generates lambda versus quantile plot
Lambda_Quantile_Plot(lmax_Store,Number_Of_Simulations)

% Calling function that generates lambda values for the 95-99 quantiles
Lambda_Quantile_Tail =  Lambda_Quantile_Tail_Distribution(lmax_Store,Number_Of_Simulations);

%%
%% Figure of Lambda versus Quantile for various sample values
% figure;
% plot(Quantile_Store,Sample10);
% hold on
% plot(Quantile_Store,Sample20);
% hold on
% plot(Quantile_Store,Sample50);
% hold on
% plot(Quantile_Store,Sample100);
% hold on
% plot(Quantile_Store,Sample200);
% xlabel('Quantile')
% ylabel('\lambda')
% legend('N = 10','N = 20','N = 50','N = 100','N = 200')

%% Lambda versus samples values for a given quantile
% Samples = [10, 20, 50, 100, 200];
% Lambda = [Sample10(5), Sample20(5), Sample50(5), Sample100(5), Sample200(5)];
% figure;
% plot(Samples, Lambda)
% xlabel('Samples')
% ylabel('\lambda')

%% Lambda versus epsilon values for a given quantile
% Epsilon = [0.25, 0.5, 0.75, 1, 2];
% Lambda = [Epsilon025(5), Epsilon050(5), Epsilon075(5), Epsilon100(5), Epsilon200(5)];
% figure;
% plot(Epsilon, Lambda)
% xlabel('\epsilon')
% ylabel('\lambda')