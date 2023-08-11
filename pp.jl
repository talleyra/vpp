using JuMP
using GLPK
using Ipopt

prices = [1, 1.4, 3, 3, 2, 0.3, -1]
n = length(prices)
model = Model(Ipopt.Optimizer)

@variable(model, 0 .<= production[i = 1:n] .<= 1)
@constraint(model, sum(production[i] for i in 1:n) <= 6)
@constraint(model, -0.3 .<= diff(production) .<= 0.3)
@NLobjective(model, Max, sum(production[i] * prices[i] for i in 1:n)/sum(production[i] for i in 1:n))

print(model)

optimize!(model)

print(model)

solution_summary(model)

round.(value.(production); digits = 4)