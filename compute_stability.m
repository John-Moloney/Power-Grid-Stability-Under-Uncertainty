function [success, is_stable, results, Beta_Tilde] = compute_stability(mpc, c, xd_max)
% function [success, is_stable, results] = compute_stability(mpc, c, xd_max)

% disable singular warning: powflow will fail anyway if so
%warnStruct = warning('off', 'MATLAB:singularMatrix');
%warning(warnStruct);
n = 10;
% n = 6;
% n = 5;
% n = 4;
% n = 3;
Beta_Tilde = zeros(n,1);

% Scale each load and generator by c.
mpc.bus(:,3) = c * mpc.bus(:,3); %scale up active power load
mpc.bus(:,4) = c * mpc.bus(:,4); %scale up reactive power load
mpc.gen(:,2) = c * mpc.gen(:,2); %scale up active power generated
% note, some will be overwritten by powerflow

[~, success] = runpf(mpc, mpoption('verbose', 0, 'out.all',0));

results = nan;
is_stable = false;
if success
    if (nargin > 2)
        est_dyn.max_xd = xd_max;
        model = pg_eff_net(mpc, est_dyn);
    else
        model = pg_eff_net(mpc);
    end
%     [results,Beta_Tilde] = pg_eff_net_lin_stability(model);  
[results,Beta_Tilde] = pg_eff_net_lin_stability(model); 
% [results] = pg_eff_net_lin_stability(model); 
    is_stable = results.max_lyap < 0;
        
end

end
