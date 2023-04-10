export d, fib, fib2

d = Dict()

function fib(i)
    get!(d, (fib, i)) do
        if i < 2
            return i
        end
        return fib(i-1) + fib(i-2)
    end
end

function fib2(i)
    get!(d, (fib2, i)) do
        if i < 2
            return i
        end
        return 10fib2(i-1) + 2*fib2(i-2)
    end
end

y() = 10

