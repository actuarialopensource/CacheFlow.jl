using CacheFlow
using Test
mbt = CacheFlow.MemoizedBasicTerm

@testset "CacheFlow.jl" begin
    empty!(d)
    @test fib(3) == 2
    @test !isempty(d)
    @test length(d) == 4 # 0:3 in cache
    @test d[(fib, 1)] == 1
    @test mbt.policies_inforce(100)[1:3] == [0.6779147517087591, 0.6818175854623849, 0.6759495191653493]
end

