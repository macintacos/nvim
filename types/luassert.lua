---@meta
-- luassert's `assert` is also callable as the builtin, which the LuaCATS class omits.

---@class luassert
---@overload fun<T, T1>(v: T, ...: T1...): std.NotNull<T>, T1...
