using Random
using Distributions
using CSV
using Tables
using DataFrames

using JuMP
using GLPK

function solve_(
    J::UnitRange{Int64}, I::UnitRange{Int64}, T::UnitRange{Int64}, U::UnitRange{Int64}, 
    Pu::Vector{Int64}, C::Vector{Int64}, 
    d::Array{Float64, 3}, N::Matrix{Vector{Int64}}, 
    c_open::Vector{Float64}, u_resource::Matrix{Float64}, min_cov::Float64 = 0.0
)
    model = Model(GLPK.Optimizer)
    # set_time_limit_sec(model, 600)

    @variable(model, z[J], Bin)
    @variable(model, x[J, U, T], Bin)
    @variable(model, y[I, U, T], Bin)

    @constraint(model, DemandRequiresSpecialist[i in I, u in U, t in T], sum(x[j, u, t] for j in N[i, u]) >= y[i, u, t])
    @constraint(model, ResourcesMustBeAvailable[u in U, t in T], sum(x[j, u, t] for j in J) <= Pu[u])
    @constraint(model, RespectMaximumCapacity[j in J, t in T], sum(x[j, u, t] for u in U) <= (C[j] * z[j]))
    @constraint(model, ToAllocateSpaceMustBeOpened[j in J, u in U, t in T], x[j, u, t] <= z[j])
    if min_cov > 0
        # if min_cov > max_cov (found by setting min_cov <= 0), there will be no solution
        @constraint(model, MinimumCoverage, sum(d[i, u, t] * y[i, u, t] for i in I, u in U, t in T) / sum(d) >= min_cov)
        # locat ion cost + personal cost
        @objective(model, Min, sum(z[j] * c_open[j] for j in J) + sum(sum.(u_resource[u] * x[:, u, :] for u in U)))
    else
        @objective(model, Max, sum(d[i, u, t] * y[i, u, t] for i in I, u in U, t in T))
    end

    optimize!(model)

    status = termination_status(model)

    if has_values(model)
        xOpt = value.(x)
        yOpt = value.(y)
        zOpt = value.(z)
    else
        return nothing, nothing, nothing, nothing, nothing, nothing
    end

    if min_cov > 0
        total_cost = objective_value(model)
        total_cov = sum(d[i, u, t] * yOpt[i, u, t] for i in I, u in U, t in T)
    else 
        loc_cost = sum(zOpt[j] * c_open[j] for j in J)
        rh_cost = sum(sum.(u_resource[u] * xOpt[:, u, :] for u in U))
        total_cost = loc_cost + rh_cost
        total_cov = objective_value(model)
    end

    println("Status: $(status) :: Served $(total_cov) = $(round(total_cov / sum(d), digits = 3)) :: Cost: $(total_cost) :: Elapsed: $(solve_time(model))")
    return total_cov / sum(d), total_cov, total_cost, xOpt, yOpt, zOpt
end

Random.seed!(42)

# Facility
J = 1:50 # facility sites
I = 1:1_000 # demand nodes

T = 1:3 # time periods // 24 / 8
U = 1:5 # types

# ["THEFT", "BATTERY", "CRIMINAL DAMAGE", "NARCOTICS", "ASSAULT"]
Pu = [50, 20, 30, 15, 30] # available capacity for alocation
Su = [3, 30, 15, 10, 5] # critical time // max ~20

C = trunc.(Int, rand(Uniform(30, 100), J[end])) # Facility Capacity

locations = CSV.read("data/cooked/dist_from_center.csv", DataFrame).Location

# costs
c_open = locations .* 1_000 .+ 10_000.0 # the greater the distance to the center, the less expensive
u_resource = [300.0 500 800.0 1_000.0 500.0] # resource_cost.csv = cost per shift

cov_cost, vOpt = [], []
for sample_number in 0:4

    push!(cov_cost, [])
    # # population to be served at demand node i, using u type at t time
    # d = trunc.(Int, rand(Uniform(5, 30), I[end], U[end], T[end]))
    crimes = CSV.read("data/cooked/sample_$(sample_number).csv", DataFrame)
    #  this is SUPER sparse (there are only I values in J * I * T matrix)
    d = [((r.type_ + 1) == u && (r.shift + 1) == t) ? 1.0 : 0.0 for r in Tables.namedtupleiterator(crimes), u in U, t in T]

    # response distace
    r = CSV.read("data/cooked/distances_$(sample_number).csv", DataFrame, transpose = true)

    # viable response distances
    N = [
        [j for (j, n) in enumerate(r[:, i] .<= Su[u]) if n] 
        for i in I, u in U
    ]

    perc_cov, total_cov, total_cost, xOpt, yOpt, zOpt = solve_(J, I, T, U, Pu, C, d, N, c_open, u_resource, 0.0)
    push!(cov_cost[sample_number + 1], (total_cov, total_cost))
    push!(vOpt, (xOpt, yOpt, zOpt))
    
    for (idx, cov) in enumerate(maximum((perc_cov - 0.5, 0.0)):0.1:minimum((perc_cov, 1)))
        perc_cov, total_cov, total_cost, xOpt, yOpt, zOpt = solve_(J, I, T, U, Pu, C, d, N, c_open, u_resource, cov)
        push!(cov_cost[sample_number + 1], (total_cov, total_cost))
    end
end

for sample_number in 1:5
    x, y, z = vOpt[sample_number]
    CSV.write("data/results/z_$(sample_number).csv", Tables.table(z))
    for t in T
        CSV.write("data/results/y/$(sample_number)_$(t).csv", Tables.table(y[:,:,t]))
        CSV.write("data/results/x/$(sample_number)_$(t).csv", Tables.table(x[:,:,t]))
    end
end

CSV.write("data/results/cov_cost.csv", Tables.table(cov_cost))

