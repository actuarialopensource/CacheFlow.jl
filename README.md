# CashFlow

[![Build Status](https://github.com/actuarialopensource/CacheFlow.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/actuarialopensource/CacheFlow.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Intent

Actuarial models for life insurance are generally built in closed source software, which makes it hard to communicate the concepts of life actuarial modeling with the broader public.

These models generally are written in a recursive style and memoization is necessary for good performance, see this blog post for an example - https://www.actuarialopensource.org/articles/memoization-and-life

There is a library for Python we want similar functionality to, the end goal is replicating the logic of this model [this model](https://github.com/lifelib-dev/lifelib/blob/main/lifelib/libraries/basiclife/BasicTerm_S/Projection/__init__.py).

## Requirements

* Project a collection of $P$ policies forward by $T$ timesteps and report the results in a human-readable way.
    * Some vectors of length $T$ are the same for all policies, like interest rates
    * Some vectors of length $P$ are the same for all timesteps, like gender
    * Running the model will produce cashflows at $T$ timesteps for $P$ policies.
        * To look at yearly total cashflows, we need to sum across the policies.
* The user should be able to focus on logic and not the mechanics of memoization.
* The user should be able to run the model once with one set of parameters, and then run it again with a different set of parameters.
    * The cache should be cleared between runs.


