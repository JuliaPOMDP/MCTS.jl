# various utility functions

"""
Return a vector of actions ranked by Q.

For debugging/ checking purposes - this may be slow
"""
function ranked_actions(policy, state)
    sanodes = policy.tree[state].sanodes
    q_val(sanode) = sanode.Q
    sorted_sanodes = sort(sanodes, by=q_val, rev=true)
    return [n.action for n in sorted_sanodes]
end

function ranked_actions(policy::DPWPlanner, state)
    actions = keys(policy.tree[state].A)
    q_val(a) = policy.tree[state].A[a].Q
    return sort!(collect(actions), by=q_val, rev=true)
end
