struct ExceptionRethrow end

default_action(::ExceptionRethrow, mdp, s, ex) = rethrow(ex)

function default_action(f::Function, mdp, s, ex)
    try
        a = f(mdp,s,ex)
        warn_default(ex,a)
        return a
    catch e
        Base.depwarn("""Modify the function definition to take three arguments, i.e., f(mdp,s,ex) instead of f(s,ex). The older version will be deprecated soon.""",
                :MCTS)
        a = f(s, ex)
        warn_default(ex, a)
        return a
    end
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
    @warn(sprint(showerror, ex))
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
