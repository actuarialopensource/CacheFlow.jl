using CacheFlow
const gpt = CacheFlow.Gpt
const mbt = CacheFlow.MemoizedBasicTerm

# we are checking for consistency between the functions in the modules
@assert gpt.monthly_basic_mortality(100) == mbt.monthly_basic_mortality(100)
# now for .lapse_rate
@assert gpt.lapse_rate(100) == mbt.lapse_rate(100)
gpt.policies_maturity(120)
mbt.policies_maturity(120)
gpt.policies_inforce(1)
mbt.policies_inforce(1)
empty!(gpt.d)
empty!(mbt.d)
# .- policies_lapse(t - 1) .- policies_death(t - 1) .- policies_maturity(t)
# check for these 3 functions on timestep 1 the differences
sum(gpt.policies_lapse(1))
sum(mbt.policies_lapse(1))
sum(gpt.policies_death(1))
sum(mbt.policies_death(1))
sum(gpt.policies_maturity(1))
sum(mbt.policies_maturity(1))
sum(gpt.policies_inforce(1))
sum(mbt.policies_inforce(1))
sum(gpt.policies_maturity(2))
sum(mbt.policies_maturity(2))
sum(gpt.policies_inforce(2))
sum(mbt.policies_inforce(2))


mbt = CacheFlow.MemoizedBasicTerm
minimum(gpt.model_points[:, :policy_term])
b = mbt.BasicMortality()
mbt.monthly_basic_mortality(0)
mbt.policies_inforce(100)
# CacheFlow.UnmemoizedBasicTerm.policies_inforce(1)
# get the length of a dataframe in Julia : length(df)
CacheFlow.UnmemoizedBasicTerm.policies_inforce(3)
CacheFlow.MemoizedBasicTerm.get_monthly_rate(10)
CacheFlow.MemoizedBasicTerm.get_annual_rate(10)
CacheFlow.MemoizedBasicTerm.annual_basic_mortality(1)
CacheFlow.MemoizedBasicTerm.lapse_rate(10)
CacheFlow.MemoizedBasicTerm.model_points

mbt.policies_inforce(1)
mbt.d
mbt.graph
empty!(mbt.graph)
empty!(mbt.d)
dd = de
# clear the dictionary

mbt.d

using DataStructures

d = DefaultDict([])
push!(d["1"], 2)
d


mbt.policies_inforce(200)[1:3]
# assert that the first three entries of  CacheFlow.MemoizedBasicTerm.policies_inforce(200) are good
@assert CacheFlow.MemoizedBasicTerm.policies_inforce(200)[1:3] == [0.000000, 0.5724017900070532, 0.000000]
@assert gpt.policies_inforce(200)[1:3] == [0.000000, 0.5724017900070532, 0.000000]
gpt.pv_net_cf()
gpt.premiums(1)
gpt.net_cf(1)
