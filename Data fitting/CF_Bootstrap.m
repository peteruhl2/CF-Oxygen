%%% Program to compute 95% confidence intervals for the CF ode model
%%% by bootstrapping the data
%%% 1/18/21

close all;

data = xlsread('C:\Users\peter\OneDrive\Desktop\cyst fib\julia stuff\ODEs\Data fitting\cf data','Rescaled');
tdata = data(:,1);
cdata = data(:,2);
fdata = data(:,3);

data = [tdata cdata fdata];

%%% =======================================================================

% fixed parameters
global lambda rcmin rfmin t_treat alpha beta

lambda = 0.22;
rcmin = 0;
rfmin = 0;
t_treat = 28.;
alpha = 1.0;
beta = 1.0;

%%% =======================================================================

%%% set up stuff for the bootstrap loop ===================================

runs = 1000;
tspan = 0 : 0.5 : 40;
steps = length(tspan);
C_results = zeros(steps,runs);
F_results = zeros(steps,runs);

% lazy, fix tomorrow, p will have 11 parameters
p_results = zeros(11,runs);

% best fitting parameters
Ec = 16.3653; % try < 16
Ac = 0.0198;
nc = 1.0376;

rf = 18.2171;

d = 0.5100;
dc = d;
df = d;

ep = 0.5743;
mu = 2.7079;
keta = 0.6281;

c0 = 0.9313;
f0 = 0.0161;
w0 = 0.0812;

tic
for i = 1:runs
    i
    p = [Ec,Ac,nc,rf,d,ep,mu,keta,c0,f0,w0];

    % get ode solution and error vectors
    [sol,C_err,F_err] = err_vec(p,tdata,cdata,fdata);

    % attach time points to errors
    all_errs = [tdata C_err F_err];

    % call bootstrap function
    new_errs = Bootstrap(all_errs);

    % add bootstraped errors to sol and get new data
    new_sol = add_error(sol, new_errs);
    new_cdata = new_sol(:,2);
    new_fdata = new_sol(:,3);

    %%% =======================================================================

    try
        tic
        [p,fval,flag,output] = fminsearch(@cf_err,p,options,tdata,new_cdata,new_fdata);
        toc
    catch
        % do nothing if there's an error
    end

    % solve ode's
    y0 = [p(9), p(10), p(11)];
    % tspan = [0 : 0.5 : 40];
    [t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
    % J = cf_err(p,tdata,cdata,fdata)
    p

    %%% store results
    C_results(:,i) = y(:,1);
    F_results(:,i) = y(:,2);
    p_results(:,i) = p;

end % bootstrap loop
toc

% get percentiles =========================================================
C_mean = zeros(length(tspan),1);
C_25 = zeros(length(tspan),1);
C_975 = zeros(length(tspan),1);

F_mean = zeros(length(tspan),1);
F_25 = zeros(length(tspan),1);
F_975 = zeros(length(tspan),1);


%%% fix the first dimension 1/19/21
p_mean = zeros(11,1);
p_25 = zeros(11,1);
p_975 = zeros(11,1);

%%% compute percentiles
for i = 1:length(tspan)
    C_mean(i) = mean(C_results(i,:));
    C_25(i) = prctile(C_results(i,:),2.5);
    C_975(i) = prctile(C_results(i,:),97.5);
    
    F_mean(i) = mean(F_results(i,:));
    F_25(i) = prctile(F_results(i,:),2.5);
    F_975(i) = prctile(F_results(i,:),97.5);
    
end

%%% get percentiles for p
for i = 1:11
    p_mean(i) = mean(p_results(i,:));
    p_25(i) = prctile(p_results(i,:),2.5);
    p_975(i) = prctile(p_results(i,:),97.5);
end



%%% plots =================================================================

hold on; box on;
plot(t, C_mean,'b','Linewidth',2)
plot(t, C_25, 'b--')
plot(t, C_975, 'b--')
plot(tdata,cdata,'bx', 'LineWidth',2)
plot(t, F_mean,'r','Linewidth',2)
plot(t, F_25, 'r--')
plot(t, F_975, 'r--')
plot(tdata,fdata,'rx', 'LineWidth',2)
xlabel('Time (days)')
ylabel('Population density')
title('Climax and Attack Populations')
legend('C mean', 'C 2.5th prctl','C 97.5th prctl','C data',...
    'F mean', 'F 2.5th prctl','F 97.5th prctl','F data','Location','w')

%%% =======================================================================




%%% Functions =============================================================

%%% cf ode function
function yp = cf_eqs(t,y,p)
% global lambda rcmin t_treat alpha beta
lambda = 0.22; rcmin = 0; t_treat = 28; alpha = 1; beta = 1;

Ec = p(1); Ac = p(2); nc = p(3);
rf = p(4);
d = p(5); ep = 0; mu = p(7); keta = p(8);

dc = d; df = d;

if t >= t_treat
    ep = p(6);
end

c = y(1);
f = y(2);
w = y(3);

yp = zeros(3,1);

yp(1) = (Ec*w^nc/(Ac^nc + w^nc) + rcmin)*c*(1 - c - alpha*f) - dc*c;
yp(2) = rf*f*(1 - f - beta*c) - df*f - ep*f;
yp(3) = lambda - mu*w - keta*c*w;

% hold on
% scatter(t,(Ec*w^nc/(Ac^nc + w^nc)+ rcmin),'bx')
% scatter(t,(Ef*Af^nf/(Af^nf + w^nf) + rfmin),'ro')

end

%%% objective function for cf_fitter
%%% this one returns SSE
function J = cf_err(p,tdata,cdata,fdata)
% solve odes
y0 = [0.8138, 0.1234, 0.15];
y0(1) = p(9); y0(2) = p(10); y0(3) = p(11);
[t,y] = ode15s(@cf_eqs,tdata,y0,[],p);

% odata = 0.22*ones(length(tdata),1);

errx = y(:,1) - cdata;
erry = y(:,2) - fdata;
% erro = y(:,3) - odata;

% J = errx'*errx + erry'*erry + erro'*erro;
J = errx'*errx + erry'*erry;
end

%%% Function to return two error vectors (and ode solution)
function [sol,C_err,F_err] = err_vec(p,tdata,cdata,fdata)
% solve ode
y0(1) = p(9); y0(2) = p(10); y0(3) = p(11);
[t,y] = ode15s(@cf_eqs,tdata,y0,[],p);

% return error vectors
C_err = y(:,1) - cdata;
F_err = y(:,2) - fdata;

% return solution too
sol = [t y];

end

%%% function to bootstrap the error vector
%%% errs is a three column matrix with the time data
%%% and two vectors of errors
function new_err = Bootstrap(errs)
N = length(errs);

% sample with replacement and sort
new_err = datasample(errs,N);
new_err = sortrows(new_err);

end

%%% function to add bootstraped error to ode solution
function new_sol = add_error(sol, err)
N = length(err);

for i = 1:N
    % find index of time point in sol
    sol_ind = find(sol(:,1) == err(i,1));
    % climax error
    sol(sol_ind,2) = sol(sol_ind,2) + err(i,2);
    % attack error
    sol(sol_ind,3) = sol(sol_ind,3) + err(i,3);    
end

new_sol = sol;

end
