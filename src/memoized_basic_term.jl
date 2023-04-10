module MemoizedBasicTerm
using DataFrames, CSV
using MortalityTables: MortalityTable

# # read a DataFrame from /Users/matthewcaseres/Documents/GitHub/CacheFlow.jl/src/mort_table.csv
mort_df = Matrix{Float64}(CSV.read("./src/mort_table.csv", DataFrame)[:, 2:end])
model_points = CSV.read("./src/model_point_table.csv", DataFrame)
issue_age = model_points[:, :age_at_entry]
policy_term= model_points[:, :policy_term]

Base.@kwdef struct BasicMortality <: MortalityTable
  rates::Matrix{Float64} = Matrix{Float64}(CSV.read("./src/mort_table.csv", DataFrame)[:, 2:end])
  issue_age::Vector{Int} = issue_age
end
duration(t::Int) = t ÷ 12
function get_annual_rate(table::BasicMortality, duration::Int)
  return table.rates[table.issue_age .+ duration .- 17, min(duration, 5)+1] # current age starts at 18, duration starts at 0
end
function get_monthly_rate(table::BasicMortality, t::Int)
  return 1 .- (1 .- get_annual_rate(table, duration(t))).^(1/12)
end
basic_mortality = BasicMortality()
monthly_basic_mortality(t) = get_monthly_rate(basic_mortality, t)
policies_death(t) = policies_inforce(t) .* monthly_basic_mortality(t)

d = Dict()
function policies_inforce(t)
  key = (policies_inforce, t)
  get!(d, key) do
    t == 0 && return ones(length(issue_age))
    policies_inforce(t - 1) .- policies_lapse(t - 1) .- policies_death(t - 1) .- policies_maturity(t)
  end
end

lapse_rate(t) = max(0.1 - 0.02 * duration(t), 0.02)
policies_lapse(t) = (policies_inforce(t) .- policies_death(t)) .* (1 - (1 - lapse_rate(t))^(1/12))

function policies_maturity(t)
  (t .== 12policy_term) .* (policies_inforce(t - 1) .- policies_lapse(t - 1) .- policies_death(t - 1))
end

end