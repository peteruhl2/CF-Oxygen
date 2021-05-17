%%% fitter with accurate antibiotic timing with fewer parameters
%%% 3/30/2020

close all;

data = xlsread('C:\Users\peter\OneDrive\Desktop\cyst fib\julia stuff\ODEs\Data fitting\cf data','Rescaled');
tdata = data(:,1);
% cdata = data(:,2)/100;
% fdata = data(:,3)/100;
cdata = data(:,2);
fdata = data(:,3);

%%% =======================================================================

% fixed parameters
global k lambda t_b t_c N0 mu b n
 
N0 = 6.7e8;
t_b = 19+7;
t_c = 33;

%%% =======================================================================
% do optimization here
options = optimset('MaxFunEvals',5000,'Display','iter');
% options = optimset('MaxFunEvals',5000);

%%% initial oxygen
x0 = 17.7082;

% parameters to fit
r = 24.6262;

beta = 18.7624; % try < 16
b = 12.4;
n = 1.0;

d = 0.1030;

ep = 1.1688;
mu = 200*23*60*24; % 1/5 min

k = 10^10;
eta = 4.1834e-4;
q = 4.9954e-5;

frac = 0.9998;

lambda = mu*x0;

p = [x0,frac,beta,r,eta,d,ep,q];


A = []; b_opt = []; Aeq = []; Beq = [];
lb = zeros(8,1);
ub = [200 1.0 25 25 1e-3 4 1.5 1e-4];


tic
% [p,fval,flag,output] = fmincon(@cf_err,p,A,b_opt,Aeq,Beq,lb,ub,[],options,tdata,cdata,fdata);
% [p,fval,flag,output] = fminsearch(@cf_err,p,options,tdata,cdata,fdata);
toc

% solve ode's
x0 = p(1);
frac = p(2);
c0 = frac*N0;
f0 = (1 - frac)*N0;

y0 = [c0; f0; x0];
tspan = [0 40];
[t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
% [t, y] = ode45(@(t,y) cf_eqs(t,y,p), tspan, y0);
J = cf_err(p,tdata,cdata,fdata)
p

%%% relative abundances
Ct = y(:,1)./(y(:,1) + y(:,2));
Ft = y(:,2)./(y(:,1) + y(:,2));

figure()
hold on; box on;
plot(t,Ct,'Linewidth',2)
plot(t,Ft,'Linewidth',2)
plot(tdata,cdata,'bx', 'LineWidth',2)
plot(tdata,fdata,'rx', 'LineWidth',2)
xlabel('Time (days)')
ylabel('Relative Abundance')
title('Climax and Attack Populations')
xline(t_b)
xline(t_c)
legend('C model','F model','C data','F data','Location','w')

figure()
plot(t,y(:,3),'Linewidth',2)
xlabel('Time (days)')
ylabel('Oxygen (\muM)')
title('Oxygen')

%%% =======================================================================
% %%% plot rc(w)
% w = y(:,3);
% rc = (p(1)*w.^p(3))./(p(2)^p(3) + w.^p(3));
% 
% figure()
% plot(t,rc)
% xlabel('Time (days)')
% ylabel('Climax growth rate')
% title('Climax growth rate')

%%% Functions =============================================================

%%% broad spectrum antibiotic function
function d = BrSpec(t,p)
    global t_b
    if t < t_b
        d = p(6);
    else 
        d = 0;
    end
end

%%% cf ode function
function yp = cf_eqs(t,y,p)
global k lambda t_c mu b n

beta = p(3);
r = p(4);
eta = p(5);
d = BrSpec(t,p);
ep = 0;
q = p(8);

lambda = mu*p(1);

if t >= t_c
    ep = p(7);
end

c = y(1);
f = y(2);
x = y(3);

yp = zeros(3,1);

yp(1) = (beta*x^n/(b^n + x^n))*c*(1 - (c + f)/k) - d*c;
% yp(2) = r*f*(1 - (f + c)/k) - d*f - ep*f - q*f*x;
yp(2) = r*f*(1 - (f + c)/k) - ep*f - q*f*x;
yp(3) = lambda - mu*x - eta*(c)*x;

% hold on
% scatter(t,(beta*x^n/(b^n + x^n)))
end

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