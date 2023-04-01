using MacroTools
using Cassette: Cassette, @context, overdub, recurse

abstract type AbstractCacheArg end

struct CacheArg <: AbstractCacheArg end

# we copy the body of a function over to a new function which has a new first argument
# of cache arg type. The new function with the cache arg type will be called from the original function.
macro insertarg(ex)
    # we insert the argument into this definition
    with_arg = splitdef(ex)
    # we change the body to simply call the new function with the cache arg
    without_arg = copy(with_arg)

    # Set up identity arguments to pass to unmemoized function, code from memoize.jl
    args = with_arg[:args]
    kws = with_arg[:kwargs]
    identargs = map(args) do arg
        arg_name, typ, slurp, default = splitarg(arg)
        if slurp || namify(typ) === :Vararg
            Expr(:..., arg_name)
        else
            arg_name
        end
    end
    identkws = map(kws) do kw
        arg_name, typ, slurp, default = splitarg(kw)
        if slurp
            Expr(:..., arg_name)
        else
            Expr(:kw, arg_name, arg_name)
        end
    end
    # code called without the cache arg should call the function with the cache arg
    without_arg[:body] = quote 
        $(with_arg[:name])(CacheArg(), $(identargs...); $(identkws...))
    end
    # we create the new function with the cache arg
    with_arg[:args] = [:(::CacheArg), (with_arg[:args])...]
    return esc(quote
        $(combinedef(with_arg))
        $(combinedef(without_arg))
    end)
end

@context MemoizeCtx
# macro inserts the CacheArg so that the overdub knows when to memoize a function
# Is there a better way to do this?
function Cassette.overdub(ctx::MemoizeCtx, f, arg::T, rest...) where T <: AbstractCacheArg
    result = get(ctx.metadata, (f, rest...), 0)
    if result === 0
        result = recurse(ctx, f, arg, rest...)
        ctx.metadata[(f, rest...)] = result
    end
    return result
end
ctx = MemoizeCtx(metadata = Dict());

# let's verify that our macro works
@insertarg cfib(n) = n < 2 ? n : cfib(n-1) + cfib(n-2)
overdub(ctx, cfib, 5)
overdub(ctx, cfib, 40) # this doesn't take forever, so it must be memoizing

# Now we need to verify that we can clear the cache, and still memoize
# This is important if someone reparameterizes a parametric function and wants to run again interactively
# make an abstract runner
abstract type AbstractRunner end
struct Runner1 <: AbstractRunner end
function Cassette.prehook(ctx::MemoizeCtx, f::AbstractRunner, args)
    empty!(ctx.metadata)
end
function (::Runner1)(t)
    return cfib(t)
end
runner1 = Runner1()
overdub(ctx, runner1, 100)

# getting more specific about the actuarial domain
# suppose the `q` mortality rate is the same for all policies at each timestep
struct Q
    rates::Matrix{Float64}
end
function (q::Q)(t::Int)::Vector{Float64}
    return q.rates[t, :]
end
@insertarg function pols_dead(t)
    if t == 0
        return zeros(100)
    else
        return pols_if(t-1).*q(t)
    end
end
@insertarg function pols_if(t)
    if t == 0
        return ones(100)
    else
        return pols_if(t-1) - pols_dead(t) # we want to cache the pols_if(t) to avoid recomputing, and analyze the cache
    end
end
struct Runner2 <: AbstractRunner end
function (::Runner2)(t)#rand to simulate someone changing parameters and re-runnning
    return pols_if(t)
end

runner2 = Runner2()
overdub(ctx, runner2, 5)