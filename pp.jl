#=
Virtual power plants and electricty markets
Exercises
=#

# Demands

using JuMP
using HiGHS
using GLPK
using Plots

prices = [20, 50, 35, 31, 48, 25]
initial = 10
minimum = 120
ramping = 20
n = length(prices)
model = Model(GLPK.Optimizer)

#@variable(model, 0 .<= consumption[i = 1:n] .<= 100)
@variable(model, consumption[i = 1:n])
for i in 1:n
    @constraint(model, consumption[i] in Semicontinuous(18, 100))
end
@constraint(model, -ramping .<= diff(consumption) .<= ramping)
@constraint(model, 0 <= consumption[1] <= 20)
@constraint(model, sum(consumption[i] for i in 1:n) >= 120)
@objective(model, Min, sum(consumption[i] * prices[i] for i in 1:n))

print(model)
optimize!(model)
solution_summary(model)
value.(consumption)
plot(value.(consumption))
objective_value(model)


# power plant

capacity         = 60
ramping_up       = 20
ramping_down     = 15
start_up_ramping = 30
shut_down_ramping= 15
initial_power_out= 0
online_cost      = 6
variable_cost    = 33
start_up_cost    = 120
shut_down_cost   = 60
prices = [20, 50, 35, 31, 48, 25]
n = length(prices)

model = Model(HiGHS.Optimizer)

@variable(model, uc[i = 1:n], Bin)
@variable(model, vsd[i = 1:n], Bin)
@variable(model, vsu[i = 1:n], Bin)

@constraint(model, c[i = 2:n], uc[i] - uc[i - 1] == vsu[i] - vsd[i])
@constraint(model, d[i = 1:n], vsu[i] + vsd[i] <= 1)

@variable(model, 0 <= p[i = 1:n] <= capacity)

@constraint(model, -ramping_down .<= diff(p) .<= ramping_up)

@objective(
    model, Max,
    sum(prices[i] * p[i] - variable_cost * p[i] - online_cost * uc[i] - start_up_cost * vsu[i] - shut_down_cost * vsd[i] for i in 1:n)
    )

print(model)

optimize!(model)

print(model)
optimize!(model)
solution_summary(model)
value.(p)
plot(value.(p))
objective_value(model)



## storage unit
using JuMP
using GLPK
using Plots

n = length(prices)
max_charging_power = 20
max_discharging_power = 20
max_energy_level = 40
initial_energy_level = 10  # Adjust the initial energy level as needed
charging_efficiency = 0.95
discharging_efficiency = 0.95

model = Model(GLPK.Optimizer)
prices = [20, 50, 35, 31, 48, 25, 23, 21, 23, 39, 23]

@variable(model, 0 <= power_charging[i = 1:n] <= max_charging_power)
@variable(model, 0 <= power_discharging[i = 1:n] <= max_discharging_power)
@variable(model, 0 <= energy_in_battery[i = 1:n] <= max_energy_level)

# Set the initial energy level constraint
#@constraint(model, energy_in_battery[1] == initial_energy_level)

# Energy balance constraints and non-negativity of energy_in_battery
for i in 1:n
    @constraint(model, energy_in_battery[i] == sum(power_charging[1:i] * charging_efficiency - power_discharging[1:i] * (1/discharging_efficiency)) + initial_energy_level)
    @constraint(model, energy_in_battery[i] >= 0)
    @constraint(model, energy_in_battery[i] <= max_energy_level)  # Ensure the battery capacity is not exceeded
end

# Define the objective function
@objective(model, Max, sum(prices[i] * (power_discharging[i] - power_charging[i]) for i in 1:n))

# Solve the optimization problem
optimize!(model)

# Extract and display results
opt_power_charging = value.(power_charging)
opt_power_discharging = value.(power_discharging)
opt_energy_in_battery = value.(energy_in_battery)

println("Optimal Charging Power   : ", round.(opt_power_charging, digits = 2))
println("Optimal Discharging Power: ", round.(opt_power_discharging, digits = 2))
println("Optimal Energy in Battery: ", round.(opt_energy_in_battery, digits = 2))
println("prices                   : ", round.(prices, digits =  2))

solution_summary(model)

plot(opt_power_discharging - opt_power_charging)