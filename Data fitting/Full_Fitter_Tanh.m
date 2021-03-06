%%% fitting CF odes with an MC routine
%%% trying with a tanh growth rate function
%%% 12/14/2020

close all;

data = xlsread('C:\Users\peter\OneDrive\Desktop\cyst fib\julia stuff\ODEs\Data fitting\cf data','Rescaled');
tdata = data(:,1);
% cdata = data(:,2)/100;
% fdata = data(:,3)/100;
cdata = data(:,2);
fdata = data(:,3);

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
% do optimization here
% options = optimset('MaxFunEvals',5000,'Display','iter','UseParallel',true);
% options = optimoptions(options,'UseParallel',true);
options = optimset('MaxFunEvals',5000,'Display','iter');
% options = optimset('MaxFunEvals',5000);

% parameters to fit
Ac = 14.6;
Bc = 24;

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

p = [Ac,Bc,rf,d,ep,mu,keta,c0,f0,w0];

A = []; b = []; Aeq = []; Beq = []; 
lb = [0 0 0 0 0 0 0.95 0 0.8*cdata(1) 0.08*fdata(1) 0.1]; 
ub = [Inf Inf Inf Inf Inf Inf Inf Inf 1.3*cdata(1) 1.3*fdata(1) 0.22];


tic
% [p,fval,flag,output] = fmincon(@cf_err,p,A,b,Aeq,Beq,lb,ub,[],options,tdata,cdata,fdata);
[p,fval,flag,output] = fminsearch(@cf_err,p,options,tdata,cdata,fdata);
toc


% solve ode's
y0 = [p(8), p(9), p(10)];
tspan = [0 40];
[t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);
J = cf_err(p,tdata,cdata,fdata)
p

% figure(); hold on; box on;
% plot(t,y(:,1),'b','Linewidth',2)
% plot(t,y(:,2),'r','Linewidth',2)
% plot(tdata,cdata,'bx', 'LineWidth',2)
% plot(tdata,fdata,'rx', 'LineWidth',2)
% xlabel('Time (days)')
% ylabel('Population density')

hold on; box on;
plot(t,y(:,1),'Linewidth',2)
plot(t,y(:,2),'Linewidth',2)
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
%%% plot rc(w)
w = y(:,3);
% rc = (p(1)*w.^p(3))./(p(2)^p(3) + w.^p(3));
rc = p(1).*tanh(p(2).*w);

figure()
plot(t,rc)
xlabel('Time (days)')
ylabel('Climax growth rate')
title('Climax growth rate')

%%% Functions =============================================================

%%% cf ode function
function yp = cf_eqs(t,y,p)
global lambda rcmin t_treat alpha beta

Ac = p(1); Bc = p(2);
rf = p(3);
d = p(4); ep = 0; mu = p(6); keta = p(7);

dc = d; df = d;

if t >= t_treat
    ep = p(5);
end

c = y(1);
f = y(2);
w = y(3);

yp = zeros(3,1);

yp(1) = Ac*tanh(Bc*w)*c*(1 - c - alpha*f) - dc*c;
yp(2) = rf*f*(1 - f - beta*c) - df*f - ep*f;
yp(3) = lambda - mu*w - keta*c*w;

% hold on
% scatter(t,(Ec*w^nc/(Ac^nc + w^nc)+ rcmin),'bx')
% scatter(t,(Ef*Af^nf/(Af^nf + w^nf) + rfmin),'ro')

end

%%% objective function for cf_fitter
function J = cf_err(p,tdata,cdata,fdata)
y0 = [0.8138, 0.1234, 0.15];
y0(1) = p(8); y0(2) = p(9); y0(3) = p(10);
[t,y] = ode15s(@cf_eqs,tdata,y0,[],p);

% odata = 0.22*ones(length(tdata),1);

errx = y(:,1) - cdata;
erry = y(:,2) - fdata;
% erro = y(:,3) - odata;

% J = errx'*errx + erry'*erry + erro'*erro;
J = errx'*errx + erry'*erry;
end