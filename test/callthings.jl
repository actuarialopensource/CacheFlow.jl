using CacheFlow
using Folds
const gpt = CacheFlow.Gpt

@assert gpt.policies_inforce(200)[1:3] == [0.000000, 0.5724017900070532, 0.000000]
@assert gpt.claims(130)[1:3] ≈ [0.0, 28.82531005791726, 0.0]
@assert gpt.expenses(100)[1:3] == [3.682616858501336, 3.703818110341339, 3.671941182132007]
@assert gpt.expenses(0)[1:3] == [305.0,305.0,305.0]

# calls to `pv_` prefixed functions appear to be expensive. These functions are sometimes called at each timestep.
# pv_claims works, but it is used in the calculation for premiums(t::Int) which can be called thousands of times potentially.
# See implementation to see why operation is expensive.
@assert gpt.pv_claims()[1:3] == [5501.19489836432, 5956.471604652321, 9190.425784230943]

