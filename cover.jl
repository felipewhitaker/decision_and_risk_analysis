using JuMP
using GLPK

using Distributions
using Random

Random.seed!(42)

# Facility
J = 1:5 # facility sites
I = 1:10 # demand nodes

T = 1:3 # time periods
U = 1:2 # types

Pu = trunc.(Int, rand(Uniform(2, 5), U[end])) # available capacity for alocation
Su = rand(Uniform(3, 10), U[end]) # critical time

C = trunc.(Int, rand(Uniform(5, 20), J[end])) # Facility Capacity

# response time
r = rand(Uniform(2, 8), J[end], I[end])

# viable response distances
N = [
    [j for (j, n) in enumerate(r[:, i] .<= Su[u]) if n] 
    for i in I, u in U
]

# population to be served at demand node i, using u type at t time
d = trunc.(Int, rand(Uniform(5, 30), I[end], U[end], T[end]))

# costs
c_open = rand(Uniform(20, 100), J[end])

model = Model(GLPK.Optimizer)

@variable(model, z[J], Bin)
@variable(model, x[J, U, T], Bin)
@variable(model, y[I, U, T], Bin)

@constraint(model, DemandRequiresSpecialist[i in I, u in U, t in T], sum(x[j, u, t] for j in N[i, u]) >= y[i, u, t])
@constraint(model, ResourcesMustBeAvailable[u in U, t in T], sum(x[j, u, t] for j in J) <= Pu[u])
@constraint(model, RespectMaximumCapacity[j in J, t in T], sum(x[j, u, t] for u in U) <= (C[j] * z[j]))
@constraint(model, ToAllocateSpaceMustBeOpened[j in J, u in U, t in T], x[j, u, t] <= z[j])
# @constraint(model, MinimumCoverage, sum(d[i, u, t] * y[i, u, t] for i in I, u in U, t in T) / sum(d) >= 0.8) # this might yield no solution

# opening cost + expansion_cost (?)
# @objective(model, Min, sum(z[j] * c_open[j] for j in J))
@objective(model, Max, sum(d[i, u, t] * y[i, u, t] for i in I, u in U, t in T))

optimize!(model)

status = termination_status(model)
total_cov = objective_value(model)
# xOpt = value.(x)
# yOpt = value.(y)
zOpt = value.(z)

println("==============================")
println("Status: ", status)
println("Served $(total_cov) = $(round(total_cov / sum(d), digits = 2))")
# println("Served: ", total_cov)
# println("Facilities: ", xOpt)
# println("Covered: ", yOpt)
println("Opened: ", zOpt')
println("==============================")