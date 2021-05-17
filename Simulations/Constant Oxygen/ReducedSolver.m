%%% quasi-steady oxygen model
%%% 5/13/21

%%% C' = (beta*lambda/(mu + eta*c))*c*(1 - (c + f)/k) - dc*c;
%%% F' = r*f*(1 - (c + f)/k) - df*f  - (q*lambda*f)/(mu + eta*c);

close all;

%%% =======================================================================

% fixed parameters
global k N0
 
N0 = 6.7e8;
k = 10^10;

%%% Ode parameters ========================================================

beta = 16.3;
r = 16.5;
d = 0.2;
q = 12.2e-3;

lambda = 9.7e7;
mu = 200*23*60*24;
eta = 2.2e-2;

p = [beta,r,d,q,...
     lambda,mu,eta];


frac = 0.85;
c0 = frac*N0;
f0 = (1 - frac)*N0;
y0 = [c0; f0];

tspan = [0 80];
[t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);


figure()
hold on; box on;
plot(t,log10(y(:,1)),'Linewidth',2)
plot(t,log10(y(:,2)),'Linewidth',2)
xlabel('Time (days)')
ylabel('Absolute Abundance')
title('Climax and Attack Populations')
legend('C model','F model')

%%% equilibria ============================================================

% time series
c = y(:,1);
f = y(:,2);

% extinction values
cxt = k*(beta*lambda - d*mu)/(d*k*eta + beta*lambda);
fxt = k*(r*mu - q*lambda - d*mu)/(r*mu);

% coexistence values
rad = sqrt(4*q*r + d*beta); 
cx1 = (beta*lambda - sqrt(beta/d)*rad*lambda - 2*r*mu)/(2*r*eta);
fx1 = -(d*k*eta - 2*k*r*eta - sqrt(d/beta)*k*eta*rad + beta*lambda - sqrt(beta/d)*lambda*rad - 2*r*mu)/(2*r*eta);

cx2 = (beta*lambda + sqrt(beta/d)*rad*lambda - 2*r*mu)/(2*r*eta);
fx2 = -(d*k*eta - 2*k*r*eta + sqrt(d/beta)*k*eta*rad + beta*lambda + sqrt(beta/d)*lambda*rad - 2*r*mu)/(2*r*eta);

% per capita growth rates
cp = @(x,y) (beta*lambda/(mu + eta*x))*(1 - (x + y)/k) - d;
fp = @(x,y) r*(1 - (x + y)/k) - d - (q*lambda)/(mu + eta*x);

% coexistence criteria
cinv = beta*q*lambda^2 + beta*d*lambda*mu - d*r*mu^2;


%%% stability ==============================================================
eig(jac(cx1,fx1,p))
eig(jac(cx2,fx2,p))



%%% funcitons =============================================================

%%% cf ode function
function yp = cf_eqs(t,y,p)
global k

beta = p(1);
r = p(2);
d = p(3);
q = p(4);
lambda = p(5);
mu = p(6);
eta = p(7);

dc = d;
df = d;

c = y(1);
f = y(2);

yp = zeros(2,1);

yp(1) = (beta*lambda/(mu + eta*c))*c*(1 - (c + f)/k) - dc*c;
yp(2) = r*f*(1 - (c + f)/k) - df*f  - (q*lambda*f)/(mu + eta*c);

hold on
scatter(t, real(log10((beta*lambda/(mu + eta*c))*(1 - (c + f)/k) - dc)),'b');
scatter(t, real(log10(r*(1 - (f + c)/k) - df  - q*lambda/(mu + eta*c))),'rx');
end

%%% jacobian function
function J = jac(c,f,p)
global k

beta = p(1);
r = p(2);
d = p(3);
q = p(4);
lambda = p(5);
mu = p(6);
eta = p(7);

J = zeros(2,2);

J(1,1) = -(eta*(d*k*eta + beta*lambda)*c^2 + 2*c*(d*k*eta + beta*lambda)*mu + ...
         mu*(f*beta*lambda - k*beta*lambda + d*k*mu))/(k*((mu+eta*c)^2));
J(1,2) = -(c*beta*lambda)/(k*(mu+eta*c));
J(2,1) = -r*f/k + (f*q*eta*lambda)/((mu+eta*c)^2);
J(2,2) = -d + r*(1 - (c+f)/k) - r*f/k - q*lambda/(mu+eta*c);


end
