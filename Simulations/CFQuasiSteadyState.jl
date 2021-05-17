# Full CF quasi steady state ode solver
# 3/31/21

cd("C:\\Users\\peter\\OneDrive\\Documents\\GitHub\\CF-Oxygen\\Simulations")

using Plots, DifferentialEquations

function cf_ode!(yp,y,p,t)
    β,b,n,r,k,d,ϵ,q,μ,η,x0 = p
    c,f = y

    λ = μ*x0
    d = BrSpec(t,p)

    # climax has non constant growth
    x = λ/(μ + η*c)
    yp[1] = β*x*c*(1 - (c+f)/k) - d*c
    yp[2] = r*f*(1 - (c+f)/k) - d*f - ϵ*f - q*f*x

end

function BrSpec(t,p)
    global t_b
    if t < t_b
        d = p[6];
    else
        d = 0;
    end
end

global t_b
# t_b = 19 + 7*10
t_b = Inf
N0 = 6.7e8

# parameters
r = 24.6262
β = 18.7624
b = 12.4
n = 1.0

# d = 0.1030
d = 6

ϵ = 1.1688*0
μ = 200*23*60*24


k = 10^10
η = 4.1834e-4*1000/5
# q = 4.9954e-5
q = 1.4


# initial conditions
frac = 0.9998

x0 = 17.74
λ = μ*x0

p = [β,b,n,r,k,d,ϵ,q,μ,η,x0]

c0 = frac*N0
f0 = (1 - frac)*N0

tspan = (0.0,30.0)
y0 = [c0, f0]

prob = ODEProblem(cf_ode!,y0,tspan,p)
sol = solve(prob)

c = sol[1,:]
f = sol[2,:]

Ct = c./(c .+ f)
Ft = f./(c .+ f)

p = plot(sol.t[c.>0],c[c.>0], label = "Climax", lw = 2, yaxis=:log)
p = plot!(sol.t[f.>0],f[f.>0], label = "Attack", lw = 2, legend=:right, xlabel = "Time (days)", ylabel = "Population Density",yaxis=:log)
# p = plot(sol.t[c.>0],c[c.>0], label = "Climax", lw = 2)
# p = plot!(sol.t[f.>0],f[f.>0], label = "Attack", lw = 2, legend=:topright, xlabel = "Time (days)", ylabel = "Population Density")

# p = plot(sol.t, Ct, label = "C", lw = 2)
# p = plot!(sol.t, Ft, label = "F", lw = 2)
display(p)


# exclusion equilibria
cs = k*(β*λ - d*μ)/(d*k*η + β*λ)
fs = k*(r*μ - q*λ - d*μ)/(r*μ)

# invasion conditions
ci = β*q*λ^2 + β*d*λ*μ - d*r*μ^2
fi = r*(d*k*η + d*μ)/(d*k*η + β*λ) - d - q*λ/(μ + η*cs)