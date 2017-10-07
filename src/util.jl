# various utility functions

"""
Return a vector of actions ranked by Q.

For debugging/ checking purposes - this may be slow
"""
function ranked_actions(policy, state)
    sanodes = policy.tree[state].sanodes
    q_val(sanode) = sanode.Q
    sorted_sanodes = sort(sanodes, by=q_val, rev=true)
    return [(n.action, n.Q) for n in sorted_sanodes]
end

function ranked_actions(policy::DPWPlanner, state)
    tree = get(policy.tree)
    snode = tree.s_lookup[state]
    sanodes = tree.children[snode]
    tuples = [(tree.a_labels[n], tree.q[n]) for n in sanodes]
    return sort!(tuples, by=last, rev=true)
end
