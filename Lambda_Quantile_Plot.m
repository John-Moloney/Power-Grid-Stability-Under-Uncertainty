% Function that generates a plot of the stored lambda values
function Lambda_Quantile_Plot(lmax_Store,Number_Of_Simulations)
Lambda_Quantile_Store = zeros(9,1);
Quantile_Store = zeros(9,1);

Sorted_lmax_Store = sort(lmax_Store);
counter = 1;
for Quantile = 10:10:90
    Quantile_Store(counter) = Quantile;
    Percentage = Quantile/100;
    Lambda_Quantile_Index = (Percentage*Number_Of_Simulations) + 1;
    Lambda_Quantile_Number = Sorted_lmax_Store(Lambda_Quantile_Index);
    Lambda_Quantile_Store(counter) = Lambda_Quantile_Number;
    counter = counter + 1;
end

% Plot the quantile versus lambda values
figure;
plot(Quantile_Store,Lambda_Quantile_Store);
xlabel('Quantile')
ylabel('\lambda')
