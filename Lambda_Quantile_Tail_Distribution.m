% Function that calculates the values for the tail of the lambda
% distribution
function Lambda_Quantile_Tail =  Lambda_Quantile_Tail_Distribution(lmax_Store,Number_Of_Simulations)
Lambda_Quantile_Store = zeros(5,1);
Quantile_Store = zeros(5,1);

Sorted_lmax_Store = sort(lmax_Store);
counter = 1;

for Quantile = 95:1:99
    Quantile_Store(counter) = Quantile;
    Percentage = Quantile/100;
    Lambda_Quantile_Index = (Percentage*Number_Of_Simulations) + 1;
    Lambda_Quantile_Number = Sorted_lmax_Store(Lambda_Quantile_Index);
    Lambda_Quantile_Store(counter) = Lambda_Quantile_Number;
    counter = counter + 1;
end

Lambda_Quantile_Tail = Lambda_Quantile_Store;