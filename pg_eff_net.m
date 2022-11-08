function [model, mpc] = pg_eff_net(mpc, est_dyn)
% PG_EFF_NET computes the paramters of the effective network model for the
% given power system.
%
%  [model, mpc] = PG_EFF_NET(mpc, est_dyn)
%
% It requires Matpower to run power flow calculation and compute the bus
% admittance matrix Y0.
%
% The dynamic parameters for the generators are defined in the matrix
% mpc.gen_dyn.  The columns are:
%
%  1    x'_{d,i} = transient reactance (in p.u.)
%  2    H_i = inertia constant (in seconds)
%  3    D_i = (combined) damping coefficient (in seconds)
%
% All should be given on the system base MVA.  If any dynamic parameters
% are missing, they will be generated using the functions specified in
% est_dyn (est_dyn.x_d, est_dyn.H, est_dyn.D).  If that is not given, then
% the default function in this file will be used.
%
% Note: I could remove the parts that deal with H and D, which are not
% needed for this computation.
%
% Last modified by Ferenc Molnar
% Added support for fictitous generators


% Code below uses Matpower constants defined by this.
define_constants

% prepare a copy of mpc, where fictitous generators are GENERATORS.
mpc_pf = mpc;
i_fic = (mpc.bus(:, BUS_TYPE) == 4);
if (sum(i_fic) > 0)
    % set type to generator
    mpc_pf.bus(i_fic, BUS_TYPE) = 2;
    
    % add mpc.fic to generators
    mpc_pf.gen = [mpc.gen ; mpc.fic];
end

% Compute power flow using Matpower, suppressing output display.
mopt = mpoption( ...
    'OUT_ALL', 0, ...
    'VERBOSE', 0, ...
    'PF_DC', 0, ...
    'OUT_SYS_SUM', 0, ...
    'OUT_BUS', 0, 'OUT_BRANCH', 0);

mpc_pf = runpf(mpc_pf, mopt);

if ~mpc_pf.success
   error('Matpower power flow calculation was not successful.')
end

%Now override the fictitous generators back to load nodes
mpc_pf.bus(i_fic, BUS_TYPE) = 1;

% Also separate out the fictitious generators from .gen
if (sum(i_fic) > 0)
    mpc_pf.fic = mpc_pf.gen(length(mpc.gen)+1 : length(mpc_pf.gen), :);
    mpc_pf.gen = mpc_pf.gen(1 : length(mpc.gen), :);
end

% finally, replace mpc with the post-processed one
mpc = mpc_pf;

% Number of generators:
ngi = size(mpc.gen,1);

% If the functions for estimating missing dynamic parameters are not given,
% use the ones defined in this file.
default_max_xd = 1;

if nargin < 2
    est_dyn.x_d = @default_x_d;
    est_dyn.H = @default_H;
    est_dyn.D = @default_D;
    est_dyn.max_xd = default_max_xd;
else
    if ~isfield(est_dyn, 'x_d')
        est_dyn.x_d = @default_x_d;
    end
    if ~isfield(est_dyn, 'H')
        est_dyn.H = @default_H;
    end
    if ~isfield(est_dyn, 'D')
        est_dyn.D = @default_D;
    end
    if ~isfield(est_dyn, 'max_xd')
        est_dyn.max_xd = default_max_xd;
    end
end

% Use mpc.gen_dyn if given.  Otherwise, generate empty place holder here to
% be filled in later with the default values. The columns are: x'_{d,i},
% H_i, and D_i. Note that indexing for given gen_dyn should be 'external'
% one (and will be converted to 'internal' below, but converted back to
% 'external' before this function returns).
model.gen_dyn = 'given';
if ~isfield(mpc,'gen_dyn')    
    %disp('mpc.gen_dyn is missing and thus estimated.')
    mpc.gen_dyn = nan(ngi,3);
    model.gen_dyn = 'estimated';
end

% Convert to the Matpower's internal indexing scheme.  This is needed
% because makeYbus requires matpower internal indexing.  According to
% Matpower help file for ext2int, "all isolated buses, off-line generators
% and branches are removed along with any generators, branches or areas
% connected to isolated buses."  "All buses are numbered consecutively,
% beginning at 1, and generators are reordered by bus number."
mpc = ext2int(mpc);
mpc = e2i_field(mpc, 'gen_dyn', 'gen');

% Common system base
baseMVA = mpc.baseMVA;

% System reference frequency omega_R (in radian):
if isfield(mpc, 'ref_freq')
    model.omega_R = 2*pi*mpc.ref_freq;
else
    model.omega_R = 2*pi*60;
    %disp('mpc.ref_freq not defined. Assuming system ref frequency of 60 Hz.')
end

% The number buses:
n = size(mpc.bus,1);
model.n = n;

% My indices for generator internal buses (gii) and generator terminal
% buses (gti), as well as the bus numbers (in mpc) for the terminal buses.
ngi = size(mpc.gen,1);
model.ngi = ngi;
[gtb,~,t2i] = unique(mpc.gen(:,GEN_BUS));
ngt = length(gtb);
model.gtb = gtb;
model.ngt = ngt;
% model.t2i = t2i;

% Other (load) buses.
is_gen = false(n,1);
is_gen(gtb) = true;
ltb = mpc.bus(~is_gen, BUS_I);
nl = length(ltb);
model.ltb = ltb;
model.nl = nl;

% Total number of nodes, including the generators' separate internal and
% terminal nodes, as well as load nodes.
N = ngi + ngt + nl;
model.N = N;

%% Estimating missing dynamic parameters

% If H_i is not given (i.e., value 'nan'), use the default method to
% estimate it.
i = isnan(mpc.gen_dyn(:,2));
mpc.gen_dyn(i,2) = est_dyn.H(abs(mpc.gen(i,PG)));
model.H = mpc.gen_dyn(:,2);

% If D_i is not given (i.e., value 'nan'), use the default method to
% estimate it. 
i = isnan(mpc.gen_dyn(:,3));
mpc.gen_dyn(i,3) = est_dyn.D(abs(mpc.gen(i,PG)));
model.D = mpc.gen_dyn(:,3);

% If x'_{d,i} is not given, use the default method to estimate it.
if (est_dyn.max_xd > 0) %negative means force set
    i = isnan(mpc.gen_dyn(:,1));    
else
    %Force estimation:
    i = true(length(mpc.gen_dyn),1);
    est_dyn.max_xd = -est_dyn.max_xd;
end

mpc.gen_dyn(i,1) = est_dyn.x_d(abs(mpc.gen(i,PG)), est_dyn.max_xd);
x_d = mpc.gen_dyn(:,1);
model.x_d = x_d;


%% Computing E
% P and Q injected at generator terminals in p.u. on system base MVA.
Pi = mpc.gen(:,PG)/baseMVA;
Qi = mpc.gen(:,QG)/baseMVA;

%%%% store these too
model.Pi = Pi;
model.Qi = Qi;

% Voltage magnitude V and phase angle phi for the generator terminal buses.
tb = mpc.gen(:,GEN_BUS); % (counting multiple generators)
V = mpc.bus(tb,VM);
phi = mpc.bus(tb,VA)/180*pi;

% Compute the complex voltage E at the internal nodes of generators and
% motors.
E = ((V + Qi.*x_d./V) + 1j*(Pi.*x_d./V)).*exp(1j*phi);
model.E = E;

%% Computing Y
% Define parts of the physical network admittance matrix Y0 (generated by
% Matpower's makeYbus function) and the admittance matrix Yd for transient
% reactances, and build the expanded admittance matrix Y0p.
Y0 = makeYbus(mpc);
Y0gl = Y0(gtb,ltb);
model.Y0gl = Y0gl;
Y0lg = Y0(ltb,gtb);
model.Y0lg = Y0lg;
Yd = sparse(1:ngi, 1:ngi, 1./(1j*x_d));
model.Yd = Yd;



model.Y0 = Y0;



% Add the shunt admittances equivalent to the given loads to the diagonal
% of Y0gg and Y0ll to obatin Y0ggt and Y0llt.
Plg = mpc.bus(gtb,PD)/baseMVA;
Qlg = mpc.bus(gtb,QD)/baseMVA;
Vg = mpc.bus(gtb,VM);
Y0ggt = Y0(gtb,gtb) + sparse(1:ngt, 1:ngt, Plg./(Vg.^2) - 1j*(Qlg./(Vg.^2)));
model.Y0ggt = Y0ggt;
Pll = mpc.bus(ltb,PD)/baseMVA;
Qll = mpc.bus(ltb,QD)/baseMVA;
Vl = mpc.bus(ltb,VM);
Y0llt = Y0(ltb,ltb) + sparse(1:nl, 1:nl, Pll./(Vl.^2) - 1j*(Qll./(Vl.^2)));
model.Y0llt = Y0llt;

% Kron reduction (using the notation in our 2013 Nat Phys paper).
Y0nn = Yd;
Y0nr = sparse(1:ngi, t2i, -1./(1j*x_d), ngi, n);
Y0rn = Y0nr.';
Y0rr = [...
    Y0ggt - diag(sum(Y0nr(:,1:ngt),1)), Y0gl;...
    Y0lg, Y0llt];
model.Yred = full([Y0nn, Y0nr; Y0rn, Y0rr]);
model.Y = full(Y0nn - Y0nr/Y0rr*Y0rn);

% Convert indexing for the power flow solution back to the original order.
mpc = i2e_field(mpc, 'gen_dyn', 'gen');
mpc = int2ext(mpc);

end

function x_d = default_x_d(P, x_d_max)
% The default method for estimating the d-axis transient reactances x'_d.
% Assign the values accoding to the empirical relation used in A.E. Motter,
% S.A. Myers, M. Anghel, & T. Nishikawa, Spontaneous synchrony in
% power-grid networks, Nat Phys 9, 191 (2013).  Impose a maximum value.

% x_d_max = 1;
% x_d_max = 2.2;

%x_d = min([92.8*P.^(-1.3), x_d_max*ones(size(P))], [], 2);
x_d = min([102.30253 * P.^(-1.35742), x_d_max*ones(size(P))], [], 2);
%disp(x_d);
end


function H = default_H(P)
% The default method for estimating the inertia constant H_i.  Assign the
% values accoding to the empirical relation used in A.E. Motter, S.A.
% Myers, M. Anghel, & T. Nishikawa, Spontaneous synchrony in
% power-grid networks, Nat Phys 9, 191 (2013).  Impose a minimum value.

H_min = 0.1;
H = max([0.04*P, H_min*ones(size(P))], [], 2);
end

function D = default_D(P)
% The default method for estimating the damping coefficient D_i. Setting
% D_i = 50 (which is what we did in the 2013 Nat Phys paper) is equivalent
% to setting
%
%   D_m = 0 * P_R/omega_R
%   D_e = 0 * P_R/omega_R
%   R = 0.02 * omega_R/P_R
%
% in the notation of the New J Phys paper.

D = 50*ones(size(P));
end



