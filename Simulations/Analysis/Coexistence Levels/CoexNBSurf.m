%%% make a surface of the equilibrium value of f for a big range of n and b

%%% in this r_c(X) = beta*x^n/(b^n + x^n)
%%% model is

%%% c' = rc*c*(1-c-f) - d*c
%%% f' = rf*f*(1-c-f) - d*f - q*lambda*f/(mu + eta*k*c)

%%% rc = (beta*lambda^n)/(lambda^n + b^n*(mu + eta*k*c)^n)
%%% rf = (r + beta*(1 - (lambda^n)/(lambda^n + b^n*(mu + eta*k*c)^n)))

%%% this one is multiple trajectories
%%% 6/4/2021

close all;
global k beta r d b mu eta lambda q n

%%% array for results =====================================================
res = 100;
N = linspace(0.1,10,res);
B = linspace(0,30,res);
Fvals = zeros(length(N),length(B));
% V = zeros(length(N), 2);

options = optimset('Display','off');
fun = @SStates;

%%% Parameters ============================================================

k = 10^10;

beta = 16.6;
r = 0.004;
d = 0.6;
b = 13.4;
n = 2.6;

mu = 200*23*60*24;
eta = 3.1e-3;

lambda = 9.6e7;
q = 3e-1;

%%% =======================================================================
%%% growth rates
rc = @(c) (beta*lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n);
rf = @(c) (r + beta*(1 - (lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n)));

%%% nullcline functions
Cp = @(c,f) (beta*lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n).*(1-c-f) - d;
Fp = @(c,f) (r + beta*(1 - (lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n))).*(1-c-f) - d - q*lambda./(mu + eta*k*c);


% hold on
for i = 1:length(N)
    for j = 1:length(B)
        [i j]
        
        %%% new value of n and b
        n = N(i);
        b = B(j);

        %%% have to bring the nullcline functions in here
        %%% growth rates
        rc = @(c) (beta*lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n);
        rf = @(c) (r + beta*(1 - (lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n)));

        %%% nullcline functions
        Cp = @(c,f) (beta*lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n).*(1-c-f) - d;
        Fp = @(c,f) (r + beta*(1 - (lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n))).*(1-c-f) - d - q*lambda./(mu + eta*k*c);

        % calculate nullcline intersection and eigenvalues
        x0 = [0.5;0.5];
        xco = fsolve(fun,x0,options);
        
        %%% get F equilibrium value, F is second component
        Fvals(i,j) = xco(2);
%         V(i,:) = cfeigs(xco);

    %     fimplicit(Cp, interval,'b','Linewidth',2)
    %     fimplicit(Fp, interval,'r','Linewidth',2)

    %     if max(V(i,:)) > 0 % unstable
    %         scatter(xco(1),xco(2),'kx','Linewidth',4)
    %     else 
    %         scatter(xco(1),xco(2),'cx','Linewidth',4)
    %     end
    end
end

%%% Coesistence point =====================================================
x0 = [0.5;0.5];
xco = fsolve(fun,x0,options);
xf = fsolve(fun,[0,1],options);
xc = fsolve(fun,[1,0],options);
x0 = fsolve(fun,[0.01,0.01],options);

%%% eigenvalues
v = cfeigs(xco);
v0 = cfeigs([0,0]);
vc = cfeigs(xc);
vf = cfeigs(xf);

%%% trajectory
c0 = 0.9;
f0 = 0.9;

y0 = [c0; f0];
tspan = [0 800];

[t, y] = ode15s(@(t,y) cf_eqs(t,y), tspan, y0);

% time series
c = y(:,1);
f = y(:,2);

%%% plots =================================================================

[X,Y] = meshgrid(N,B);
hold on; box on;
surf(X,Y,Fvals')
xlabel('n')
ylabel('b')
h = colorbar;
ylabel(h, 'F equilibrium value')
shading interp


%%% functions =============================================================

%%% cf ode function
function yp = cf_eqs(t,y)
global k beta r d b mu eta lambda q n

c = y(1);
f = y(2);

yp = zeros(2,1);

yp(1) = (beta*lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n).*c*(1-c-f) - d*c;
yp(2) = (r + beta*(1 - (lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n))).*f*(1-c-f) - d*f - q*lambda*f./(mu + eta*k*c);

% hold on
% scatter(t,(beta*lambda/(mu + eta*c))*(1 - c - f) - dc,'b')
% scatter(t,r*(k*f*(mu + eta*c)/(q*lambda) - 1)*(1 - c - f) - df,'r')
end

%%% steady state residual function
function F = SStates(x)
global k beta r d b mu eta lambda q n

c = x(1);
f = x(2);

F(1) = (beta*lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n).*c*(1-c-f) - d*c;
F(2) = (r + beta*(1 - (lambda^n)./(lambda^n + (b^n)*(mu + eta*k*c).^n))).*f*(1-c-f) - d*f - q*lambda*f./(mu + eta*k*c);

end

%%% function that returns eigenvalues of a point (c,f)
function v = cfeigs(x)
global k beta r d b mu eta lambda q n

c = x(1);
f = x(2);

%%% big terms
A = (c*k*eta + mu);
B = (lambda^n)/(lambda^n + b^n*A^n);
D = (b^n)*(1-c-f)*k*n*beta*eta*(lambda^n)*(A^(n-1))/((lambda^n + (b^n)*A^n)^2);


J = zeros(2,2);

J(1,1) = -d - c*D - c*beta*B + (1-c-f)*beta*B;
J(1,2) = -c*beta*B;
J(2,1) = f*k*q*eta*lambda/(A^2) + f*D - f*(r + beta*(1-B));
J(2,2) = -d - q*lambda/A + (1-c-f)*(r + beta*(1-B)) - f*(r + beta*(1-B));

v = eigs(J);

end