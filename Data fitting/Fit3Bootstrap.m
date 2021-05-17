%%% Program to compute 95% confidence intervals for the CF ode model
%%% by bootstrapping the erros
%%% 3/10/21

close all;

data = xlsread('C:\Users\peter\OneDrive\Desktop\cyst fib\julia stuff\ODEs\Data fitting\cf data','Rescaled');
tdata = data(:,1);
cdata = data(:,2);
fdata = data(:,3);

%%% =======================================================================

% fixed parameters
global k t_b t_c N0 mu

N0 = 6.7e8;
t_b = 19;
t_c = 33;

%%% set up stuff for the bootstrap loop ===================================

% set results for number of parameters
runs = 100;
n_params = 12;
p_results = zeros(n_params,runs);

%%% best fitting parameters
%%% initial oxygen
x0 = 14.6287;

% parameters to fit
r = 0.0046;

beta = 16.6388; % try < 16
b = 13.4256;
n = 2.6626;

dn = 0.6045; % natural death rate
dbs = 6.7686; % death due to bs antibiotics
gamma = 0.8976; % fractional reduction of bs antibiotics in killing attack

ep = 1.2124;
mu = 200*23*60*24; % 1/5 min

k = 10^10;
eta = 3.1611e-4;
q = 3.2747e-5;

frac = 0.8659;

% lambda = mu*x0;

p = [x0,frac,beta,r,...
     eta,dbs,dn,gamma,...
     ep,q,b,n];

% tspan = [0 : 0.5 : 40];
% [t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
% 
% 
% 
% [sol,C_err,F_err] = err_vec(p,tdata,cdata,fdata)

%%% optimization bounds
A = []; b_opt = []; Aeq = []; Beq = [];
lb = zeros(12,1);
ub = [200 1.0 25 25 1e-3 10 10 1 1.5 1e-4 20 5];

%%% allocate memory for results
%%% solve once for timespan
% solve ode's
x0 = p(1);
frac = p(2);
c0 = frac*N0;
f0 = (1 - frac)*N0;

y0 = [c0; f0; x0];
tspan = [0 40];
[t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);


steps = length(t);
C_results = zeros(steps,runs);
F_results = zeros(steps,runs);

tic
for i = 1:runs
    i
 
    p = [x0,frac,beta,r,...
         eta,dbs,dn,gamma,...
         ep,q,b,n];
 
    %%% ===================================================================

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
        [p,fval,flag,output] = fmincon(@cf_err,p,A,b_opt,Aeq,Beq,lb,ub,[],options,tdata,new_cdata,new_fdata);
        toc
    catch
        % do nothing if there's an error
    end

    % solve ode's
    y0 = [p(2)*N0; (1 - p(2))*N0; p(1)];
    tspan = [0 40];
    [t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
    
    % tspan = [0 : 0.5 : 40];
    [t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
    % J = cf_err(p,tdata,cdata,fdata)
    % p

    %%% relative abundances
    Ct = y(:,1)./(y(:,1) + y(:,2));
    Ft = y(:,2)./(y(:,1) + y(:,2));

    %%% store results
    C_results(1:length(Ct),i) = Ct;
    F_results(1:length(Ft),i) = Ft;
    p_results(:,i) = p;

end % bootstrap loop
toc

% get percentiles =========================================================
C_mean = zeros(length(t),1);
C_25 = zeros(length(t),1);
C_975 = zeros(length(t),1);

F_mean = zeros(length(t),1);
F_25 = zeros(length(t),1);
F_975 = zeros(length(t),1);


%%% fix the first dimension 1/19/21
p_mean = zeros(n_params,1);
p_25 = zeros(n_params,1);
p_975 = zeros(n_params,1);

%%% compute percentiles
for i = 1:length(t)
    C_mean(i) = mean(C_results(i,:));
    C_25(i) = prctile(C_results(i,:),2.5);
    C_975(i) = prctile(C_results(i,:),97.5);
    
    F_mean(i) = mean(F_results(i,:));
    F_25(i) = prctile(F_results(i,:),2.5);
    F_975(i) = prctile(F_results(i,:),97.5);
    
end

%%% get percentiles for p
for i = 1:n_params
    p_mean(i) = mean(p_results(i,:));
    p_25(i) = prctile(p_results(i,:),2.5);
    p_975(i) = prctile(p_results(i,:),97.5);
end


%%% =======================================================================
%%% Plots =================================================================
%%% relative abundances
Ct = y(:,1)./(y(:,1) + y(:,2));
Ft = y(:,2)./(y(:,1) + y(:,2));

figure()
hold on; box on;
plot(t,C_mean,'b','Linewidth',2)
plot(t,C_25,'b--','Linewidth',1.5)
plot(t,C_975,'b--','Linewidth',1.5)
plot(t,F_mean,'r','Linewidth',2)
plot(t,F_25,'r--','Linewidth',1.5)
plot(t,F_975,'r--','Linewidth',1.5)
xlabel('Time (days)')
ylabel('Relative Abundance')
title('Climax and Attack Populations')

% figure()
% hold on; box on;
% plot(t,Ct,'Linewidth',2)
% plot(t,Ft,'Linewidth',2)
% plot(tdata,cdata,'bx', 'LineWidth',2)
% plot(tdata,fdata,'rx', 'LineWidth',2)
% xlabel('Time (days)')
% ylabel('Relative Abundance')
% title('Climax and Attack Populations')
% xline(t_b)
% xline(t_c)
% legend('C model','F model','C data','F data','Location','w')

% figure()
% plot(t,y(:,3),'Linewidth',2)
% xlabel('Time (days)')
% ylabel('Oxygen (\muM)')
% title('Oxygen')


%%% =======================================================================

%%% Functions =============================================================

%%% broad spectrum antibiotic function
function dbs = BrSpec(t,p)
    global t_b
    if t < t_b
        dbs = p(6);
    else 
        dbs = 0;
    end
end

%%% cf ode function
function yp = cf_eqs(t,y,p)
global k t_c mu

beta = p(3);
r = p(4);
eta = p(5);
dbs = BrSpec(t,p);
dn = p(7);
gamma = p(8);
ep = 0;
q = p(10);
b = p(11);
n = p(12);

lambda = mu*p(1);

if t >= t_c
    ep = p(9);
end

%%% total death rates
dc = dn + dbs;
df = dn + gamma*dbs;

c = y(1);
f = y(2);
x = y(3);

yp = zeros(3,1);

yp(1) = (beta*x^n/(b^n + x^n))*c*(1 - (c + f)/k) - dc*c;
% yp(2) = r*f*(1 - (f + c)/k) - df*f - ep*f - q*f*x;
yp(2) = (r + beta*(1 - x^n/(b^n + x^n)))*f*(1 - (f + c)/k) - df*f - ep*f - q*f*x;
yp(3) = lambda - mu*x - eta*(c)*x;

% hold on
% scatter(t,(beta*x^n/(b^n + x^n)),'bo')
% scatter(t,(r + beta*(1 - x^n/(b^n + x^n))),'rx')
end

%%% objective function for cf_fitter
%%% this one returns SSE
%%% objective function for cf_fitter
function J = cf_err(p,tdata,cdata,fdata)
global N0 

x0 = p(1);
frac = p(2);

c0 = frac*N0;
f0 = (1 - frac)*N0;

y0 = [c0; f0; x0];
[t,y] = ode15s(@cf_eqs,tdata,y0,[],p);

Ct = y(:,1)./(y(:,1) + y(:,2));
Ft = y(:,2)./(y(:,1) + y(:,2));

errx = Ct - cdata;
erry = Ft - fdata;

J = errx'*errx + erry'*erry;
% J = errx'*errx;
% J = erry'*erry;
end

%%% Function to return two error vectors (and ode solution in rel. abund.)
function [sol,C_err,F_err] = err_vec(p,tdata,cdata,fdata)
global N0
% solve ode
x0 = p(1);
frac = p(2);

c0 = frac*N0;
f0 = (1 - frac)*N0;
y0 = [c0; f0; x0];
[t,y] = ode15s(@cf_eqs,tdata,y0,[],p);

% return error vectors
Ct = y(:,1)./(y(:,1) + y(:,2));
Ft = y(:,2)./(y(:,1) + y(:,2));

C_err = Ct - cdata;
F_err = Ft - fdata;

% return solution too
sol = [t y];
sol(:,2) = Ct;
sol(:,3) = Ft;

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