struct ExceptionRethrow end

default_action(::ExceptionRethrow, mdp, s, ex) = rethrow(ex)
default_action(f::Function, mdp, s, ex) = f(s, ex)
default_action(p::POMDPs.Policy, mdp, s, ex) = action(p, s)
default_action(sol::POMDPs.Solver, mdp, s, ex) = action(solve(sol, mdp), s)
default_action(a, mdp, s, ex) = a

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
    warn("Using default action $a")
    return a
end
