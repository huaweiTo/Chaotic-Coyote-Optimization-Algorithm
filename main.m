function  main
% coded by huawei Tong, 2021-04-21
clc ; close all;clear;
global Initial_Value_1 Initial_Value_2 FOBJ;
Initial_Value_1=0.8;
Initial_Value_2=0.3;
global  nfevalMAX lu  Np Nc  D;
D           = 10;                    % Problem dimension
lu          = [-10*ones(1,D);
    10*ones(1,D)];       % Seach space
nfevalMAX   = 20000;                 % Stopping criteria
Np          = 20;                    % Number of packs
Nc          = 5;                     % Number of coyotes
% Optimization problem
FOBJ        = @(x) sum(x.^2);
ExperTime=10; % setup experiments times
for i = 1:ExperTime
    disp(['=====Experiments:  ',num2str(i),'====='])
    [GlobalParams,GlobalMin,costs] =CCOA;
    disp(['The cost is ',num2str(GlobalMin)]);
end
end

