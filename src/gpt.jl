module Gpt
using DataFrames, CSV, LinearAlgebra, Statistics, Memoize

mort_df = Matrix{Float64}(CSV.read(joinpath(@__DIR__, "models", "mort_table.csv"), DataFrame)[:, 2:end])
const model_points = CSV.read(joinpath(@__DIR__, "models", "model_point_table.csv"), DataFrame)
const issue_age = model_points[:, :age_at_entry]
Base.@kwdef struct BasicMortality
    rates::Matrix{Float64} = Matrix{Float64}(CSV.read(joinpath(@__DIR__, "models", "mort_table.csv"), DataFrame)[:, 2:end])
    issue_age::Vector{Int} = model_points[:, :age_at_entry]
end

const final_timestep = Ref(500)

duration(t::Int) = t ÷ 12

get_annual_rate(table::BasicMortality, duration::Int) = table.rates[table.issue_age .+ duration .- 17, min(duration, 5)+1]
get_monthly_rate(table::BasicMortality, t::Int) = 1 .- (1 .- get_annual_rate(table, duration(t))).^(1/12)
basic_mortality = BasicMortality()
monthly_basic_mortality(t) = get_monthly_rate(basic_mortality, t)
policies_death(t) = policies_inforce(t) .* monthly_basic_mortality(t)

# policies_inforce(t) = t == 0 ? ones(length(issue_age)) : (t > 12policies_term() ? 0 : policies_inforce(t - 1) .- policy_lapses(t - 1) .- policies_death(t - 1) .- policies_maturity(t))
const cache_policies_inforce = Dict{Tuple{Int64},Any}()
@memoize Returns(cache_policies_inforce)() function policies_inforce(t)
  t == 0 && return ones(length(issue_age))
  policies_inforce(t - 1) .- policies_lapse(t - 1) .- policies_death(t - 1) .- policies_maturity(t)
end
policies_lapse(t) = (policies_inforce(t) .- policies_death(t)) .* (1 - (1 - lapse_rate(t))^(1/12))
lapse_rate(t) = max(0.1 - 0.02 * duration(t), 0.02)

policies_term() = model_points[:, :policy_term]

function policies_maturity(t)
    (t .== 12policies_term()) .* (policies_inforce(t - 1) .- policies_lapse(t - 1) .- policies_death(t - 1))
  end

const sum_assured = model_points[:, :sum_assured]
const zero_spot = CSV.read("src/models/disc_rate_ann.csv", DataFrame)[:, :zero_spot]
const sex = model_points[:, :sex]
const inflation_rate = 0.01
const expense_acq = 300
const expense_maint = 60
const loading_prem = 0.50
const projection_length = 20 * 12

age(t::Int) = age_at_entry() .+ duration(t)
age_at_entry() = model_points[:, :age_at_entry]
claim_pp(t::Int) = sum_assured #unused
claims(t::Int) = claim_pp(t) .* policies_death(t)
commissions(t::Int) = duration(t) == 0 ? premiums(t) : 0
disc_factors() = [(1 + disc_rate_mth(t))^(-t) for t in final_timestep[]]
disc_rate_mth(t::Int)::Float64 = (1 + disc_rate_ann(duration(t)))^(1/12) - 1
disc_rate_ann(t::Int)::Float64 = 0.05 # where does that come from? t is unused
expenses(t::Int) = t == 0 ? expense_acq .+ (policies_inforce(t) .* (expense_maint / 12) .* inflation_factor(t)) : (policies_inforce(t) .* (expense_maint / 12) .* inflation_factor(t))
inflation_factor(t::Int) = (1 .+ inflation_rate).^(t/12)
# this is tested but performance concerns.
disc_factor(t) = (1 + zero_spot[duration(t)+1])^(-t/12)
pv_claims() = sum(t -> claims(t) * disc_factor(t), 0:500)
pv_commissions() = sum(t -> commissions(t) * disc_factor(t), 0:final_timestep[])
pv_expenses() = sum(t -> expenses(t) * disc_factor(t), 0:final_timestep[])
pv_pols_if() = sum(t -> policies_inforce(t) * disc_factor(t), 0:final_timestep[])
pv_premiums() = sum(t -> premiums(t) * disc_factor(t), 0:final_timestep[])

# See that net_premium_pp() references pv_claims, an expensive function. This gets called for every t during premiums(t::Int).
net_premium_pp() = pv_claims() ./ pv_pols_if()
const cache_premiums_pp = Dict{Tuple{},Any}()
@memoize Returns(cache_premiums_pp)() premium_pp() = round.((1 .+ loading_prem) .* net_premium_pp(); digits = 2)
premiums(t::Int) = premium_pp() .* policies_inforce(t)
pv_net_cf() = pv_premiums() .- pv_claims() .- pv_expenses() .- pv_commissions()

net_cf(t::Int) = premiums(t) .- claims(t) .- expenses(t) .- commissions(t)

function result_cf()
    t_len = 0:12*policies_term()
    data = Dict(
        "Premiums" => premiums.(t_len),
        "Claims" => claims.(t_len),
        "Expenses" => expenses.(t_len),
        "Commissions" => commissions.(t_len),
        "Net Cashflow" => net_cf.(t_len)
    )
    return DataFrame(data)
end

function result_pv()
    cols = ["Premiums", "Claims", "Expenses", "Commissions", "Net Cashflow"]
    pvs = [pv_premiums(), pv_claims(), pv_expenses(), pv_commissions(), pv_net_cf()]
    per_prem = [x ./ pv_premiums() for x in pvs]

    return DataFrame(Dict(
            "PV" => pvs,
            "% Premium" => per_prem
        ), cols)
end

end
