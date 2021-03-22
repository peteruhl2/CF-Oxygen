%%% Two hill function CAM model
%%% 3/22/2020

close all;

data = xlsread('C:\Users\peter\OneDrive\Desktop\cyst fib\julia stuff\ODEs\Data fitting\cf data','Rescaled');
tdata = data(:,1);
% cdata = data(:,2)/100;
% fdata = data(:,3)/100;
cdata = data(:,2);
fdata = data(:,3);

%%% =======================================================================

% fixed parameters
global k lambda t_treat N0 d mu x0
 
N0 = 6.7e8;
lambda = 1.32;
t_treat = 28.;

%%% =======================================================================
% do optimization here
options = optimset('MaxFunEvals',5000,'Display','iter');
% options = optimset('MaxFunEvals',5000);

%%% initial oxygen
x0 = 18;

% parameters to fit
r = 5.7543;

beta = 20.6970; % try < 16
b = 12.8139;
n = 1.0;

d = 6;

ep = 0.4614;
mu = x0*12*60*24; % 1/5 min

k = 10^10;
eta = 1.0075e-5;
q = 0.0010;

frac = 0.9866;

lambda = mu*x0;

p = [b,n,q,ep,frac,r,beta,eta];


A = []; b_opt = []; Aeq = []; Beq = [];
lb = zeros(8,1);
ub = [150 10.0 1 2 1 40 40 1e-3];


tic
% [p,fval,flag,output] = fmincon(@cf_err,p,A,b_opt,Aeq,Beq,lb,ub,[],options,tdata,cdata,fdata);
% [p,fval,flag,output] = fminsearch(@cf_err,p,options,tdata,cdata,fdata);
toc


% solve ode's
frac = p(5);
c0 = frac*N0;
f0 = (1 - frac)*N0;
% x0 = 90;

y0 = [c0; f0; x0];
tspan = [0 40];
% tspan = tdata;
[t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
% J = cf_err(p,tdata,cdata,fdata)
p
% [sol,C_err,F_err] = err_vec(p,tdata,cdata,fdata);

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
ylabel('Population density')
title('Climax and Attack Populations')
legend('C model','F model','C data','F data','Location','w')

figure()
plot(t,y(:,3),'Linewidth',2)
xlabel('Time (days)')
ylabel('Oxygen')
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

%%% cf ode function
function yp = cf_eqs(t,y,p)
global k lambda t_treat d mu

b = p(1); 
n = p(2);
q = p(3);
ep = 0; 
r = p(6);
beta = p(7);
eta = p(8);

if t >= t_treat
    ep = p(4);
end

c = y(1);
f = y(2);
x = y(3);

yp = zeros(3,1);

yp(1) = (beta*x^n/(b^n + x^n))*c*(1 - (c + f)/k) - d*c;
% yp(2) = r*f*(1 - (f + c)/k) - d*f - ep*f - q*f*x;
yp(2) = (r + beta*(1 - x^n/(b^n + x^n)))*f*(1 - (f + c)/k) - d*f - ep*f - q*f*x;
yp(3) = lambda - mu*x - eta*(c+f)*x;

hold on
scatter(t,(beta*x^n/(b^n + x^n)),'o')
scatter(t,(r + beta*(1 - x^n/(b^n + x^n))),'x')
end