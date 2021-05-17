%%% surf of eta and epsilon vs exacerbation time
%%% 5/11/2020

% close all;

data = xlsread('C:\Users\peter\OneDrive\Desktop\cyst fib\julia stuff\ODEs\Data fitting\cf data','Rescaled');
tdata = data(:,1);
% cdata = data(:,2)/100;
% fdata = data(:,3)/100;
cdata = data(:,2);
fdata = data(:,3);

%%% =======================================================================

% fixed parameters
global k lambda t_b t_c N0 mu

% global parameters for treatment
global t_start t_end treat_true
 
N0 = 6.7e8;
t_b = 19*0;
t_c = 33*Inf;

%%% =======================================================================

%%% do this simulation for a lot of eta values
Eta = linspace(1.883e-4, 7.883e-4, 50);
Ep = linspace(0.5,4.302,50);
results = zeros(length(Eta),length(Ep));

for i = 1:length(Eta)
    for j = 1:length(Ep)
        [i j]
        
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

        ep = Ep(j);
        mu = 200*23*60*24; % 1/5 min

        k = 10^10;
        eta = Eta(i); % increased a bit for simulations
        q = 3.2747e-5;

        frac = 0.8659;

        % lambda = mu*x0;
        lambda = 9.6901e+07;

        p = [x0,frac,beta,r,...
             eta,dbs,dn,gamma,...
             ep,q,b,n];


        %%% Treament simulation stuff in here =====================================
        t_start = Inf;
        t_end = Inf;
        treat_true = 0;


        %%% =======================================================================

        % solve ode's
        x0 = p(1);
        frac = p(2);
        c0 = frac*N0;
        f0 = (1 - frac)*N0;

        y0 = [c0; f0; x0];
        tspan = [0 180];
        [t, y] = ode15s(@(t,y) cf_eqs(t,y,p), tspan, y0);

        %%% relative abundances
        Ct = y(:,1)./(y(:,1) + y(:,2));
        Ft = y(:,2)./(y(:,1) + y(:,2));

        %%% this stuff will find the time between exacerbations ===================
        %%% =======================================================================

        swtchpts = find(islocalmax(Ft)); % Ft local maxes
        swtimes = t(swtchpts); % times when Ft changes direction

        % get time between switches
        try
            etime = swtimes(end) - swtimes(end-1);
        catch
            % do nothing if error
        end

        %%% save results
        results(i,j) = etime;
    end
end

figure()
[X,Y] = meshgrid(Eta,Ep);
contourf(X,Y,results');
colorbar
xlabel('Oxygen consumption rate')
ylabel('Clindamycin strength')
title('Time between Exacerbations')



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
global k lambda t_c mu 
global t_start t_end treat_true

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

%%% check if we're treating and activate if we are
% check if f > c, if so get start and end times
if y(2)/(y(1) + y(2)) > 0.5
    t_start = t;
    t_end = t_start + 10;
end

% if current time is between start and end
% use antibiotic
if t_start <= t && t <= t_end
    ep = p(9);
else 
    ep = 0;
end
% [t ep]


%%% total death rates
dc = dn + dbs;
df = dn + gamma*dbs;

c = y(1);
f = y(2);
x = y(3);

yp = zeros(3,1);

yp(1) = (beta*x^n/(b^n + x^n))*c*(1 - (c + f)/k) - dc*c;
yp(2) = (r + beta*(1 - x^n/(b^n + x^n)))*f*(1 - (f + c)/k) - df*f - ep*f - q*f*x;
yp(3) = lambda - mu*x - eta*(c)*x;

% hold on
% scatter(t,(beta*x^n/(b^n + x^n)),'bo')
% scatter(t,(r + beta*(1 - x^n/(b^n + x^n))),'rx')
end