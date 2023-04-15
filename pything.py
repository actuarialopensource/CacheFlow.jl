from collections import defaultdict
from functools import lru_cache, wraps
from typing import Any, Callable, Dict, Tuple

class LRUCache:
    def __init__(self, maxsize=None):
        self.cache = lru_cache(maxsize)(self._uncached_get)

    def __getitem__(self, key):
        return self.cache(key)

    def __contains__(self, key):
        return key in self.cache

    def get_cache_key(self, args, kwargs):
        return args

    def _uncached_get(self, key):
        raise NotImplementedError

class NumPyArrayLRUCache(LRUCache):
    def __init__(self, maxsize=None):
        super().__init__(maxsize)
        self.aggregate_sums = {}

    def _uncached_get(self, key):
        raise NotImplementedError

    def __setitem__(self, key, value):
        self.aggregate_sums[key] = value.sum()
        self.cache.__wrapped__ = lambda k: value
        self.cache.cache_clear()
        self.cache(key)

class Cash:
    def __init__(self, cache_factory: Callable[[], LRUCache]):
        self.cache_factory = cache_factory
        self.lru_caches = defaultdict(cache_factory)

    def reset(self):
        self.lru_caches.clear()

    def get_aggregate_sum(self, func_name: str, key: Tuple) -> Any:
        cache = self.lru_caches.get(func_name)
        if isinstance(cache, NumPyArrayLRUCache):
            return cache.aggregate_sums.get(key)

    def __call__(self, f: Callable[[int], Any]) -> Callable:
        @wraps(f)
        def g(*args, **kwargs) -> Any:
            cache = self.lru_caches[f.__name__]
            cache_key = cache.get_cache_key(args, kwargs)
            if cache_key not in cache:
                cache[cache_key] = f(*args, **kwargs)
            return cache[cache_key]
        return g

def numpy_cache_factory(maxsize=None):
    return lambda: NumPyArrayLRUCache(maxsize=maxsize)

def regular_cache_factory(maxsize=None):
    return lambda: LRUCache(maxsize=maxsize)

class CacheManager:
    def __init__(self, numpy_cache_maxsize=None, regular_cache_maxsize=None):
        self.numpy_cash = Cash(numpy_cache_factory(maxsize=numpy_cache_maxsize))
        self.regular_cash = Cash(regular_cache_factory(maxsize=regular_cache_maxsize))

    def numpy_decorator(self, f: Callable[[int], Any]) -> Callable:
        return self.numpy_cash(f)

    def regular_decorator(self, f: Callable[[int], Any]) -> Callable:
        return self.regular_cash(f)

    def reset(self):
        self.numpy_cash.reset()
        self.regular_cash.reset()

    numpy = numpy_decorator
    regular = regular_decorator

cache_manager = CacheManager(numpy_cache_maxsize=100, regular_cache_maxsize=100)

@cache_manager.numpy
def function_with_numpy_cache(t: int):
    ...

@cache_manager.regular
def function_with_regular_cache(t: int):
    ...
