using CacheFlow
mbt = CacheFlow.MemoizedBasicTerm
# CacheFlow.UnmemoizedBasicTerm.policies_inforce(1)
# get the length of a dataframe in Julia : length(df)
CacheFlow.UnmemoizedBasicTerm.policies_inforce(3)
CacheFlow.MemoizedBasicTerm.monthly_basic_mortality(10)
CacheFlow.MemoizedBasicTerm.lapse_rate(10)

mbt.policies_inforce(100)
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



# assert that the first three entries of  CacheFlow.MemoizedBasicTerm.policies_inforce(100) are [0.6779147517087591, 0.6818175854623849, 0.6759495191653493]
@assert CacheFlow.MemoizedBasicTerm.policies_inforce(100)[1:3] == [0.6779147517087591, 0.6818175854623849, 0.6759495191653493]
