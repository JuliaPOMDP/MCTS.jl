struct ExceptionRethrow end

default_action(::ExceptionRethrow, mdp, s, ex) = rethrow(ex)

function default_action(f::Function, mdp, s, ex)
    a = f(s, ex)
    warn_default(ex, a)
    return a
end

function default_action(p::POMDPs.Policy, mdp, s, ex)
    a = action(p, s)
    warn_default(ex, a)
    return a
end

function default_action(sol::POMDPs.Solver, mdp, s, ex)
    a = action(solve(sol, mdp), s)
    warn_default(ex, a)
    return a
end

function default_action(a, mdp, s, ex)
    warn_default(ex, a)
    return a
end

function warn_default(ex, a)
    @warn("Exception captured while planning; using default action $a", exception=ex, maxlog=1)
end

"""
    ReportWhenUsed(a)

When the planner fails, returns action `a`, but also prints the exception.
"""
struct ReportWhenUsed{T}
    a::T
end

function default_action(r::ReportWhenUsed, mdp, s, ex)
    showerror(STDERR, ex)
    a = default_action(r.a, mdp, s, ex)
    @warn("Using default action $a")
    return a
end

"""
    SilentDefault(a)

When the planner fails, return action `a` without printing anything.
"""
struct SilentDefault{T}
    a::T
end

default_action(r::SilentDefault, mdp, s, ex) = default_action(r.a, mdp, s, ex)
