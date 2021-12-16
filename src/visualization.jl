using D3Trees
using Colors

"""
Return text to display below the node corresponding to state or action s
"""
node_tag(s) = string(s)

"""
Return text to display in the tooltip for the node corresponding to state or action s
"""
tooltip_tag(s) = node_tag(s)

function D3Trees.D3Tree(policy::MCTSPlanner, root_state; kwargs...)
    # check to see if visualization was enabled
    @warn("""
         D3Tree(planner::MCTSPlanner, root_state) is deprecated and may be removed in the future. Instead, please use

             a, info = action_info(planner, state)
             D3Tree(info[:tree])

         Make sure that the tree_in_info solver option is set to true. You can also get this info from a POMDPToolbox History

             info = first(ainfo_hist(hist))
             D3Tree(info[:tree])
         """)
    if !policy.solver.enable_tree_vis
        error("""
              Tree visualization was not enabled for this policy.

              Construct the solver with $(typeof(policy.solver))(enable_tree_vis=true, ...) to enable.
              """)
    end
    return D3Tree(policy.tree, root_state; kwargs...)
end


function D3Trees.D3Tree(policy::DPWPlanner; kwargs...)
    @warn("""
         D3Tree(planner::DPWPlanner) is deprecated and may be removed in the future. Instead, please use

             a, info = action_info(planner, state)
             D3Tree(info[:tree])

         Make sure that the tree_in_info solver option is set to true. You can also get this info from a POMDPToolbox History

             info = first(ainfo_hist(hist))
             D3Tree(info[:tree])
         """)
    return D3Tree(policy.tree; kwargs...)
end


function D3Trees.D3Tree(tree::MCTSTree, root_state=tree.root; title="MCTS tree", kwargs...)
    if tree._vis_stats == nothing
        error("""
              Visualization was not enabled for this tree.

              Construct the MCTS solver with 'enable_tree_vis=true' to enable.
              """)
    end

    vs = tree._vis_stats
    nsas = length(vs)
    nsa = tree._a_id_counter[] - 1
    nodes = Vector{Dict{String, Any}}(undef, 1 + nsas + nsa)

    # root node
    if haskey(tree.states, root_state)
        root_node = tree.states[root_state]
    else
        error("Could not find state $root_state in tree for visualization.")
    end
    nodes[1] = Dict("type"=>:state,
                    "child_d3ids"=>[1 + nsas + c.id for c in children(root_node)],
                    "tag"=>node_tag(root_state),
                    "tt_tag"=>tooltip_tag(root_state),
                    "n"=>total_n(root_node),
                    "total_n"=>total_n(root_node),
                    "parent_n"=>total_n(root_node))

    # state-action nodes
    states_dict = Dict{Int, StateNode}()
    actions_dict = Dict{Int, ActionNode}()
    for snode in values(tree.states)
        states_dict[snode.id] = snode
        for sanode in children(snode)
            actions_dict[sanode.id] = sanode
            a = sanode.a_label
            nodes[1 + nsas + sanode.id] = Dict("type"=>:action,
                                               "child_d3ids"=>Int[],
                                               "tag"=>node_tag(a),
                                               "tt_tag"=>tooltip_tag(a),
                                               "n"=>n(sanode),
                                               "q"=>q(sanode))
        end
    end

    # state-action-state nodes
    for (i, ((said, sid), count)) in enumerate(vs)
        sanode = actions_dict[said]
        snode = states_dict[sid]
        s = snode.s_label
        nodes[1 + i] = Dict("type"=>:state,
                            "child_d3ids"=>[1 + nsas + c.id for c in children(snode)],
                            "tag"=>node_tag(s),
                            "tt_tag"=>tooltip_tag(s),
                            "n"=>count,
                            "total_n"=>total_n(snode),
                            "parent_n"=>n(sanode))
        # add as a child to corresponding sa node
        push!(nodes[1 + nsas + said]["child_d3ids"], 1 + i)

        # add parent_n to all children
        for csan in children(snode)
            csaid = csan.id
            nodes[1 + nsas + csaid]["parent_n"] = total_n(snode)
        end
    end

    for csan in children(root_node)
        csaid = csan.id
        nodes[1 + nsas + csaid]["parent_n"] = total_n(root_node)
    end

    return D3Tree(nodes; title=title, kwargs...)
end

function D3Trees.D3Tree(nodes::Vector{Dict{String, Any}}; title="Julia D3Tree", kwargs...)
    len = length(nodes)
    children = Vector{Vector{Int}}(undef, len)
    text = Vector{String}(undef, len)
    tooltip = Vector{String}(undef, len)
    style = fill("", len)
    link_style = fill("", len)
    max_q = maximum(get(n, "q", 0.0) for n in nodes)
    min_q = minimum(get(n, "q", 0.0) for n in nodes)
    for i in 1:len
        n = nodes[i]
        children[i] = n["child_d3ids"]
        if n["type"] == :state
            text[i] = @sprintf("""
                               %25s
                               N: %6d
                               """,
                               n["tag"], n["total_n"])
            tooltip[i] = """
                         $(n["tt_tag"])
                         N: $(n["total_n"])
                         """
            w = 20.0 * sqrt(n["n"] / n["parent_n"])
            link_style[i] = "stroke-width:$(w)px"
        elseif n["type"] == :action
            text[i] = @sprintf("""
                               %25s
                               Q: %6.2f
                               N: %6d
                               """,
                               n["tag"], n["q"], n["n"])
            tooltip[i] = """
                         $(n["tt_tag"])
                         Q: $(n["q"])
                         N: $(n["n"])
                         """

            rel_q = (n["q"] - min_q) / (max_q - min_q)
            color = weighted_color_mean(rel_q, colorant"green", colorant"red")
            style[i] = "stroke:#$(hex(color))"
            w = 20.0 * sqrt(n["n"] / n["parent_n"])
            link_style[i] = "stroke-width:$(w)px"
        else
            @warn("Unrecognized node type when constructing D3Tree.")
        end
    end
    return D3Tree(children;
                  text=text,
                  tooltip=tooltip,
                  style=style,
                  link_style=link_style,
                  title=title,
                  kwargs...
                 )
end


function D3Trees.D3Tree(tree::DPWTree; title="MCTS-DPW Tree", kwargs...)
    lens = length(tree.total_n)
    lensa = length(tree.n)
    len = lens + lensa
    children = Vector{Vector{Int}}(undef, len)
    text = Vector{String}(undef, len)
    tt = fill("", len)
    style = fill("", len)
    link_style = fill("", len)
    max_q = maximum(tree.q)
    min_q = minimum(tree.q)

    for s in 1:lens
        children[s] = tree.children[s] .+ lens
        text[s] =  @sprintf("""
                            %25s
                            N: %6d
                            """,
                            node_tag(tree.s_labels[s]),
                            tree.total_n[s]
                           )
        tt[s] = """
                $(tooltip_tag(tree.s_labels[s]))
                N: $(tree.total_n[s])
                """
        for sa in tree.children[s]
            w = 20.0*sqrt(tree.n[sa]/tree.total_n[s])
            link_style[sa+lens] = "stroke-width:$(w)px"
        end
    end
    for sa in 1:lensa
        children[sa+lens] = let
            sp_children = if !isempty(tree.unique_transitions)
                last.(filter(((sanode,spnode),) -> sanode == sa, tree.unique_transitions))
            else
                first.(tree.transitions[sa])
            end
            @assert length(sp_children) == tree.n_a_children[sa]
            collect(sp_children)
        end

        text[sa+lens] = @sprintf("""
                                 %25s
                                 Q: %6.2f
                                 N: %6d
                                 """,
                                 node_tag(tree.a_labels[sa]),
                                 tree.q[sa],
                                 tree.n[sa]
                                )
        tt[sa+lens] = """
                      $(tooltip_tag(tree.a_labels[sa]))
                      Q: $(tree.q[sa])
                      N: $(tree.n[sa])
                      """

        rel_q = (tree.q[sa]-min_q)/(max_q-min_q)
        if isnan(rel_q)
            color = colorant"gray"
        else
            color = weighted_color_mean(rel_q, colorant"green", colorant"red")
        end
        style[sa+lens] = "stroke:#$(hex(color))"
    end
    return D3Tree(children;
                  text=text,
                  tooltip=tt,
                  style=style,
                  link_style=link_style,
                  title=title,
                  kwargs...
                 )
end
