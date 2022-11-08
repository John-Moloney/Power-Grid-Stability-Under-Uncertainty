% Function that generates a histogram of the stored lambda values
function Histogram(lmax_Store)
figure;
histogram(lmax_Store)
xlabel('\lambda_{L}')
ylabel('Frequency')