function mpc = test_system_10_gen_beta_equals_data


%TEST_SYSTEM_10GEN   10-generator test system.
%   mpc = TEST_SYSTEM_10GEN generates data for the New England system
%   (MATPOWER case39) with the dynamic parameters taken from
%
%       M. Pai, Energy Function Analysis for Power System Stability,
%       Norwell, Kluwer Academic (1989)
%
%   Comments from the original dataset 'case39 in MATPOWER:
%
%   Data taken from [1] with the following modifications/additions:
%
%       - renumbered gen buses consecutively (as in [2] and [4])
%       - added Pmin = 0 for all gens
%       - added Qmin, Qmax for gens at 31 & 39 (copied from gen at 35)
%       - added Vg based on V in bus data (missing for bus 39)
%       - added Vg, Pg, Pd, Qd at bus 39 from [2] (same in [4])
%       - added Pmax at bus 39: Pmax = Pg + 100
%       - added line flow limits and area data from [4]
%       - added voltage limits, Vmax = 1.06, Vmin = 0.94
%       - added identical quadratic generator costs
%       - increased Pmax for gen at bus 34 from 308 to 508
%         (assumed typo in [1], makes initial solved case feasible)
%       - re-solved power flow
% 
%   Notes:
%       - Bus 39, its generator and 2 connecting lines were added
%         (by authors of [1]) to represent the interconnection with
%         the rest of the eastern interconnect, and did not include
%         Vg, Pg, Qg, Pd, Qd, Pmin, Pmax, Qmin or Qmax.
%       - As the swing bus, bus 31 did not include and Q limits.
%       - The voltages, etc in [1] appear to be quite close to the
%         power flow solution of the case before adding bus 39 with
%         it's generator and connecting branches, though the solution
%         is not exact.
%       - Explicit voltage setpoints for gen buses are not given, so
%         they are taken from the bus data, however this results in two
%         binding Q limits at buses 34 & 37, so the corresponding
%         voltages have probably deviated from their original setpoints.
%       - The generator locations and types are as follows:
%           1   30      hydro
%           2   31      nuke01
%           3   32      nuke02
%           4   33      fossil02
%           5   34      fossil01
%           6   35      nuke03
%           7   36      fossil04
%           8   37      nuke04
%           9   38      nuke05
%           10  39      interconnection to rest of US/Canada
%
%   This is a solved power flow case, but it includes the following
%   violations:
%       - Pmax violated at bus 31: Pg = 677.87, Pmax = 646
%       - Qmin violated at bus 37: Qg = -1.37,  Qmin = 0
%
%   References:
%   [1] G. W. Bills, et.al., "On-Line Stability Analysis Study"
%       RP90-1 Report for the Edison Electric Institute, October 12, 1970,
%       pp. 1-20 - 1-35.
%       prepared by E. M. Gulachenski - New England Electric System
%                   J. M. Undrill     - General Electric Co.
%       "generally representative of the New England 345 KV system, but is
%        not an exact or complete model of any past, present or projected
%        configuration of the actual New England 345 KV system.
%   [2] M. A. Pai, Energy Function Analysis for Power System Stability,
%       Kluwer Academic Publishers, Boston, 1989.
%       (references [3] as source of data)
%   [3] Athay, T.; Podmore, R.; Virmani, S., "A Practical Method for the
%       Direct Analysis of Transient Stability," IEEE Transactions on Power
%       Apparatus and Systems , vol.PAS-98, no.2, pp.573-584, March 1979.
%       URL: http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=4113518&isnumber=4113486
%       (references [1] as source of data)
%   [4] Data included with TC Calculator at http://www.pserc.cornell.edu/tcc/
%       for 39-bus system.

%   MATPOWER
%   $Id: case39.m,v 1.14 2010/03/10 18:08:13 ray Exp $

% Comments regarding copyright
%
% Copyright (C) 2015  Takashi Nishikawa
% 
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or (at
% your option) any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
% USA.

% Last modified by John Moloney on 09/11/2022

%% dynamic data added by T. Nishikawa on 1/8/2014
%% Dynamic data last altered by J. Moloney to include uncertainty on 09/11/2022
mpc.ref_freq = 60;

% The mean beta values for each generator whereby the mean beta values
% included are the single optimal beta value if optimising in the absence of
% uncertainty
Beta_Mean = [7.75,7.75,7.75,7.75,7.75,7.75,7.75,7.75,7.75,7.75];

% The standard deviation for the beta distribution for each generator
Standard_Deviation = 1;

Beta_Standard_Deviation = zeros(length(Beta_Mean),1);
for i = 1:10
    Beta_Standard_Deviation(i) = Standard_Deviation;
end

Inertia = [42, 30.3, 35.3, 28.6, 26, 34.8, 26.4, 24.3, 34.5, 500];
Beta = zeros(10,1);

for i = 1:length(Beta_Mean)
    Beta(i) = normrnd(Beta_Mean(i),Beta_Standard_Deviation(i));
end

D = zeros(10,1);

for i = 1:length(Beta_Mean)
   D(i) = (2)*(Inertia(i))*(Beta(i));
end

% x'_d  H   D
% Original values (true beta values)
mpc.gen_dyn = [
   0.0310     42      D(1)
   0.0697     30.3    D(2)
   0.0531     35.3    D(3)
   0.0436     28.6    D(4)
   0.1320     26      D(5)
   0.0500     34.8    D(6)
   0.0490     26.4    D(7)
   0.0570     24.3    D(8)
   0.0570     34.5    D(9)
   0.0060     500     D(10)
];


%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

% Mean values for the real and reactive power demand
P_D_Mean = [97.6, 0, 322, 500, 0, 0, 233.8, 522, 6.5, 0, 0, 8.53, 0, 0, 320, 329, 0, 158, 0, 680, 274,...
    0, 247.5, 308.6, 224, 139, 281, 206, 283.5, 0, 9.2, 0, 0, 0, 0, 0, 0, 0, 1104];
Q_D_Mean = [44.2, 0, 2.4, 184, 0, 0, 84, 176.6, -66.6, 0, 0, 88, 0, 0, 153, 32.3, 0, 30, 0, 103, 115, 0,...
    84.6, -92.2, 47.2, 17, 75.5, 27.6, 26.9, 0, 4.6, 0, 0, 0, 0, 0, 0, 0, 0, 250];

% Specifying the uncertainty in the real and reactive power demand
Standard_Deviation_Demand = 1;
P_D_Standard_Deviation = zeros(39,1);
Q_D_Standard_Deviation = zeros(39,1);
for i = 1:39
    P_D_Standard_Deviation(i) = Standard_Deviation_Demand;
    Q_D_Standard_Deviation(i) = Standard_Deviation_Demand;
end

P_G = zeros(39,1);
Q_G = zeros(39,1);

% Creating distribuitons for the real and reactive power demand
for i = 1:39
    P_G(i) = normrnd(P_D_Mean(i),P_D_Standard_Deviation(i));
    Q_G(i) = normrnd(Q_D_Mean(i),Q_D_Standard_Deviation(i));
end

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	1	P_G(1)	Q_G(1)	0	0	2	1.0393836	-13.536602	345	1	1.06	0.94;
	2	1	P_G(2)	Q_G(2)	0	0	2	1.0484941	-9.7852666	345	1	1.06	0.94;
	3	1	P_G(3)	Q_G(3)	0	0	2	1.0307077	-12.276384	345	1	1.06	0.94;
	4	1	P_G(4)	Q_G(4)	0	0	1	1.00446	-12.626734	345	1	1.06	0.94;
	5	1	P_G(5)	Q_G(5)	0	0	1	1.0060063	-11.192339	345	1	1.06	0.94;
	6	1	P_G(6)	Q_G(6)	0	0	1	1.0082256	-10.40833	345	1	1.06	0.94;
	7	1	P_G(7)	Q_G(7)	0	0	1	0.99839728	-12.755626	345	1	1.06	0.94;
	8	1	P_G(8)	Q_G(8)	0	0	1	0.99787232	-13.335844	345	1	1.06	0.94;
	9	1	P_G(9)	Q_G(9)	0	0	1	1.038332	-14.178442	345	1	1.06	0.94;
	10	1	P_G(10)	Q_G(10)	0	0	1	1.0178431	-8.170875	345	1	1.06	0.94;
	11	1	P_G(11)	Q_G(11)	0	0	1	1.0133858	-8.9369663	345	1	1.06	0.94;
	12	1	P_G(12)	Q_G(12)	0	0	1	1.000815	-8.9988236	345	1	1.06	0.94;
	13	1	P_G(13)	Q_G(13)	0	0	1	1.014923	-8.9299272	345	1	1.06	0.94;
	14	1	P_G(14)	Q_G(14)	0	0	1	1.012319	-10.715295	345	1	1.06	0.94;
	15	1	P_G(15)	Q_G(15)	0	0	3	1.0161854	-11.345399	345	1	1.06	0.94;
	16	1	P_G(16)	Q_G(16)	0	0	3	1.0325203	-10.033348	345	1	1.06	0.94;
	17	1	P_G(17)	Q_G(17)	0	0	2	1.0342365	-11.116436	345	1	1.06	0.94;
	18	1	P_G(18)	Q_G(18)	0	0	2	1.0315726	-11.986168	345	1	1.06	0.94;
	19	1	P_G(19)	Q_G(19)	0	0	3	1.0501068	-5.4100729	345	1	1.06	0.94;
	20	1	P_G(20)	Q_G(20)	0	0	3	0.99101054	-6.8211783	345	1	1.06	0.94;
	21	1	P_G(21)	Q_G(21)	0	0	3	1.0323192	-7.6287461	345	1	1.06	0.94;
	22	1	P_G(22)	Q_G(22)	0	0	3	1.0501427	-3.1831199	345	1	1.06	0.94;
	23	1	P_G(23)	Q_G(23)	0	0	3	1.0451451	-3.3812763	345	1	1.06	0.94;
	24	1	P_G(24)	Q_G(24)	0	0	3	1.038001	-9.9137585	345	1	1.06	0.94;
	25	1	P_G(25)	Q_G(25)	0	0	2	1.0576827	-8.3692354	345	1	1.06	0.94;
	26	1	P_G(26)	Q_G(26)	0	0	2	1.0525613	-9.4387696	345	1	1.06	0.94;
	27	1	P_G(27)	Q_G(27)	0	0	2	1.0383449	-11.362152	345	1	1.06	0.94;
	28	1	P_G(28)	Q_G(28)	0	0	3	1.0503737	-5.9283592	345	1	1.06	0.94;
	29	1	P_G(29)	Q_G(29)	0	0	3	1.0501149	-3.1698741	345	1	1.06	0.94;
	30	2	P_G(30)	Q_G(30)	0	0	2	1.0499	-7.3704746	345	1	1.06	0.94;
	31	3	P_G(31)	Q_G(31)	0	0	1	0.982	0	345	1	1.06	0.94;
	32	2	P_G(32)	Q_G(32)	0	0	1	0.9841	-0.1884374	345	1	1.06	0.94;
	33	2	P_G(33)	Q_G(33)	0	0	3	0.9972	-0.19317445	345	1	1.06	0.94;
	34	2	P_G(34)	Q_G(34)	0	0	3	1.0123	-1.631119	345	1	1.06	0.94;
	35	2	P_G(35)	Q_G(35)	0	0	3	1.0494	1.7765069	345	1	1.06	0.94;
	36	2	P_G(36)	Q_G(36)	0	0	3	1.0636	4.4684374	345	1	1.06	0.94;
	37	2	P_G(37)	Q_G(37)	0	0	2	1.0275	-1.5828988	345	1	1.06	0.94;
	38	2	P_G(38)	Q_G(38)	0	0	3	1.0265	3.8928177	345	1	1.06	0.94;
	39	2	P_G(39)	Q_G(39)	0	0	1	1.03	-14.535256	345	1	1.06	0.94;
];

% Mean values of the real and reactive power output 
P_G_Mean = [250, 677.871, 650, 632, 508, 650, 560, 540, 830, 1000];
Q_G_Mean = [161.762, 221.574, 206.965, 108.293, 166.688, 210.661, 100.165, -1.36945, 21.7327, 78.4674];

% Specifying the uncertainty the in real and reactive power output 
Standard_Deviation_Generator = 1;
P_G_Standard_Deviation = zeros(10,1);
Q_G_Standard_Deviation = zeros(10,1);
for i = 1:10
    P_G_Standard_Deviation(i) = Standard_Deviation_Generator;
    Q_G_Standard_Deviation(i) = Standard_Deviation_Generator;
end

P_G = zeros(10,1);
Q_G = zeros(10,1);

% Creating distribuitons for the real and reactive power output 
for i = 1:length(Beta_Mean)
    P_G(i) = normrnd(P_G_Mean(i),P_G_Standard_Deviation(i));
    Q_G(i) = normrnd(Q_G_Mean(i),Q_G_Standard_Deviation(i));
end



%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	30	P_G(1)	    Q_G(1)	400	    140	1.0499	100	1	1040	0	0	0	0	0	0	0	0	0	0	0	0;
	31	P_G(2)	    Q_G(2)	300	   -100	0.982	100	1	646	    0	0	0	0	0	0	0	0	0	0	0	0;
	32	P_G(3)	    Q_G(3)	300	    150	0.9841	100	1	725	    0	0	0	0	0	0	0	0	0	0	0	0;
	33	P_G(4)	    Q_G(4)	250	     0	0.9972	100	1	652	    0	0	0	0	0	0	0	0	0	0	0	0;
	34	P_G(5)	    Q_G(5)	167	     0	1.0123	100	1	508	    0	0	0	0	0	0	0	0	0	0	0	0;
	35	P_G(6)	    Q_G(6)	300	   -100	1.0494	100	1	687	    0	0	0	0	0	0	0	0	0	0	0	0;
	36	P_G(7)	    Q_G(7)	240	     0	1.0636	100	1	580	    0	0	0	0	0	0	0	0	0	0	0	0;
	37	P_G(8)	    Q_G(8)	250	     0	1.0275	100	1	564	    0	0	0	0	0	0	0	0	0	0	0	0;
	38	P_G(9)	    Q_G(9)	300	   -150	1.0265	100	1	865	    0	0	0	0	0	0	0	0	0	0	0	0;
	39	P_G(10)	    Q_G(10)	300	   -100	1.03	100	1	1100	0	0	0	0	0	0	0	0	0	0	0	0;
];

% Mean values for the resistance and reactance
R_Mean = [0.0035, 0.001, 0.0013, 0.007, 0, 0.0013, 0.0011, 0.0008, 0.0008, 0.0002, 0.0008, 0.0006, 0.0007,...
    0, 0.0004, 0.0023, 0.001, 0.0004, 0.0004, 0, 0.0016, 0.0016, 0.0009, 0.0018, 0.0009, 0.0007, 0.0016,...
    0.0008, 0.0003, 0.0007, 0.0013, 0.0007, 0.0007, 0.0009, 0.0008, 0.0006, 0, 0.0022, 0.0005, 0.0032,...
    0.0006, 0.0014, 0.0043, 0.0057, 0.0014, 0.0008];
X_Mean = [0.0411, 0.025, 0.0151, 0.0086, 0.0181, 0.0213, 0.0133, 0.0128, 0.0129, 0.0026,...
    0.0112, 0.0092, 0.0082, 0.025, 0.0046, 0.0363, 0.025, 0.0043, 0.0043, 0.02, 0.0435,...
    0.0435, 0.0101, 0.0217, 0.0094, 0.0089, 0.0195, 0.0135, 0.0059, 0.0082, 0.0173, 0.0138,...
    0.0142, 0.018, 0.014, 0.0096, 0.0143, 0.035, 0.0272, 0.0323, 0.0232, 0.0147, 0.0474, 0.0625, 0.0151, 0.0156];

% Specifying the uncertainty in the resistance and reactance
Standard_Deviation_Admittance = 0.001;
R_Standard_Deviation = zeros(46,1);
X_Standard_Deviation = zeros(46,1);
for i = 1:46
    R_Standard_Deviation(i) = Standard_Deviation_Admittance;
    X_Standard_Deviation(i) = Standard_Deviation_Admittance;
end

R = zeros(46,1);
X = zeros(46,1);

% Creating distribuitons for the resistance and reactance
for i = 1:46
    R(i) = normrnd(R_Mean(i),R_Standard_Deviation(i));
    X(i) = normrnd(X_Mean(i),X_Standard_Deviation(i));
end

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	2	R(1)	X(1)	0.6987	600	600	600	0	0	1	-360	360;
	1	39	R(2)	X(2)	0.75	1000	1000	1000	0	0	1	-360	360;
	2	3	R(3)	X(3)	0.2572	500	500	500	0	0	1	-360	360;
	2	25	R(4)	X(4)	0.146	500	500	500	0	0	1	-360	360;
	2	30	R(5)	X(5)	0	900	900	2500	1.025	0	1	-360	360;
	3	4	R(6)	X(6)	0.2214	500	500	500	0	0	1	-360	360;
	3	18	R(7)	X(7)	0.2138	500	500	500	0	0	1	-360	360;
	4	5	R(8)	X(8)	0.1342	600	600	600	0	0	1	-360	360;
	4	14	R(9)	X(9)	0.1382	500	500	500	0	0	1	-360	360;
	5	6	R(10)	X(10)	0.0434	1200	1200	1200	0	0	1	-360	360;
	5	8	R(11)	X(11)	0.1476	900	900	900	0	0	1	-360	360;
	6	7	R(12)	X(12)	0.113	900	900	900	0	0	1	-360	360;
	6	11	R(13)	X(13)	0.1389	480	480	480	0	0	1	-360	360;
	6	31	R(14)	X(14)	0	1800	1800	1800	1.07	0	1	-360	360;
	7	8	R(15)	X(15)	0.078	900	900	900	0	0	1	-360	360;
	8	9	R(16)	X(16)	0.3804	900	900	900	0	0	1	-360	360;
	9	39	R(17)	X(17)	1.2	900	900	900	0	0	1	-360	360;
	10	11	R(18)	X(18)	0.0729	600	600	600	0	0	1	-360	360;
	10	13	R(19)	X(19)	0.0729	600	600	600	0	0	1	-360	360;
	10	32	R(20)	X(20)	0	900	900	2500	1.07	0	1	-360	360;
	12	11	R(21)	X(21)	0	500	500	500	1.006	0	1	-360	360;
	12	13	R(22)	X(22)	0	500	500	500	1.006	0	1	-360	360;
	13	14	R(23)	X(23)	0.1723	600	600	600	0	0	1	-360	360;
	14	15	R(24)	X(24)	0.366	600	600	600	0	0	1	-360	360;
	15	16	R(25)	X(25)	0.171	600	600	600	0	0	1	-360	360;
	16	17	R(26)	X(26)	0.1342	600	600	600	0	0	1	-360	360;
	16	19	R(27)	X(27)	0.304	600	600	2500	0	0	1	-360	360;
	16	21	R(28)	X(28)	0.2548	600	600	600	0	0	1	-360	360;
	16	24	R(29)	X(29)	0.068	600	600	600	0	0	1	-360	360;
	17	18	R(30)	X(30)	0.1319	600	600	600	0	0	1	-360	360;
	17	27	R(31)	X(31)	0.3216	600	600	600	0	0	1	-360	360;
	19	20	R(32)	X(32)	0	900	900	2500	1.06	0	1	-360	360;
	19	33	R(33)	X(33)	0	900	900	2500	1.07	0	1	-360	360;
	20	34	R(34)	X(34)	0	900	900	2500	1.009	0	1	-360	360;
	21	22	R(35)	X(35)	0.2565	900	900	900	0	0	1	-360	360;
	22	23	R(36)	X(36)	0.1846	600	600	600	0	0	1	-360	360;
	22	35	R(37)	X(37)	0	900	900	2500	1.025	0	1	-360	360;
	23	24	R(38)	X(38)	0.361	600	600	600	0	0	1	-360	360;
	23	36	R(39)	X(39)	0	900	900	2500	1	0	1	-360	360;
	25	26	R(40)	X(40)	0.531	600	600	600	0	0	1	-360	360;
	25	37	R(41)	X(41)	0	900	900	2500	1.025	0	1	-360	360;
	26	27	R(42)	X(42)	0.2396	600	600	600	0	0	1	-360	360;
	26	28	R(43)	X(43)	0.7802	600	600	600	0	0	1	-360	360;
	26	29	R(44)	X(44)	1.029	600	600	600	0	0	1	-360	360;
	28	29	R(45)	X(45)	0.249	600	600	600	0	0	1	-360	360;
	29	38	R(46)	X(46)	0	1200	1200	2500	1.025	0	1	-360	360;
];