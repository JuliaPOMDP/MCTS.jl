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
    if !policy.solver.enable_tree_vis
        error("""
              Tree visualization was not enabled for this policy.

              Construct the solver with $(typeof(policy.solver))(enable_tree_vis=true, ...) to enable.
              """)
    end
    return D3Tree(policy.tree, root_state; kwargs...)
end

function D3Trees.D3Tree(policy::DPWPlanner; kwargs...)
    warn("""
         D3Tree(planner::DPWPlanner) is deprecated and may be removed in the future. Instead, please use
             
             a, info = action_info(planner, state)
             D3Tree(info[:tree])

         Make sure that the tree_in_info solver option is set to true. You can also get this info from a POMDPToolbox History
         
             info = first(ainfo_hist(hist))
             D3Tree(info[:tree])
         """)
    return D3Tree(get(policy.tree); kwargs...)
end


# Note: creating all these dictionaries is a convoluted and inefficient way to do it
function D3Trees.D3Tree(tree::Dict, root_state; title="MCTS tree", kwargs...)
    next_id = 2
    node_dict = Dict{Int, Dict{String, Any}}()
    s_dict = Dict{Any, Int}()
    sa_dict = Dict{Any, Int}()
    for (s, sn) in tree
        if s == root_state
            this_id = 1
        else
            this_id = next_id
        end
        # create state node
        node_dict[this_id] = sd = Dict("id"=>this_id,
                                       "type"=>:state,
                                       "children_ids"=>Array{Int}(0),
                                       "tag"=>node_tag(s),
                                       "tt_tag"=>tooltip_tag(s),
                                       "N"=>sn.N
                                       )
        s_dict[s] = this_id
        if this_id == next_id
            next_id += 1
        end

        max_N = maximum(san.N for san in sn.sanodes)
        # create action nodes
        for san in sn.sanodes
            a = san.action
            node_dict[next_id] = Dict("id"=>next_id,
                                      "type"=>:action,
                                      "children_ids"=>Array{Int}(0),
                                      "tag"=>node_tag(a),
                                      "tt_tag"=>tooltip_tag(a),
                                      "N"=>san.N,
                                      "Q"=>san.Q,
                                      "max_N"=>max_N
                                      )
            push!(sd["children_ids"], next_id)
            sa_dict[(s,a)] = next_id
            next_id += 1
        end
    end

    if !haskey(node_dict, 1)
        error("""
              MCTS tree visualization: tree does not have a node for state $root_state.
              """)
    end

    # go back and refill action nodes
    for (s, sn) in tree
        for san in sn.sanodes
            a = san.action
            for sp in get(san._vis_stats)
                sad = node_dict[sa_dict[(s,a)]]
                if haskey(s_dict, sp)
                    push!(sad["children_ids"], s_dict[sp])
                else
                    node_dict[next_id] = Dict("id"=>next_id,
                                       "type"=>:state,
                                       "children_ids"=>Array{Int}(0),
                                       "tag"=>node_tag(sp),
                                       "tt_tag"=>tooltip_tag(sp),
                                       "N"=>0
                                       )
                    push!(sad["children_ids"], next_id)
                    next_id += 1
                end
            end
        end
    end

    return D3Tree(node_dict; title=title, kwargs...)
end

function D3Trees.D3Tree(node_dict::Dict{Int, Dict{String, Any}}; title="Julia D3Tree", kwargs...)
    len = length(node_dict)
    children = Vector{Vector{Int}}(len)
    text = Vector{String}(len)
    tooltip = Vector{String}(len)
    style = fill("", len)
    link_style = fill("", len)
    max_Q = maximum(get(n, "Q", 0.0) for n in values(node_dict))
    min_Q = minimum(get(n, "Q", 0.0) for n in values(node_dict))
    for i in 1:len
        n = node_dict[i]
        children[i] = n["children_ids"]
        if n["type"] == :state
            text[i] = @sprintf("""
                               %25s
                               N: %6d
                               """,
                               n["tag"], n["N"])
            tooltip[i] = """
                         $(n["tt_tag"])
                         N: $(n["N"])
                         """
        elseif n["type"] == :action
            text[i] = @sprintf("""
                               %25s
                               Q: %6.2f
                               N: %6d
                               """,
                               n["tag"], n["Q"], n["N"])
            tooltip[i] = """
                         $(n["tt_tag"])
                         Q: $(n["Q"])
                         N: $(n["N"])
                         """

            rel_Q = (n["Q"]-min_Q)/(max_Q-min_Q)
            color = weighted_color_mean(rel_Q, colorant"green", colorant"red")
            style[i] = "stroke:#$(hex(color))"
            #TODO Max N
            w = 20.0*sqrt(n["N"]/n["max_N"])
            link_style[i] = "stroke-width:$(w)px"
        else
            warn("Unrecognized node type when constructing D3Tree.")
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
    children = Vector{Vector{Int}}(len)
    text = Vector{String}(len)
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
        children[sa+lens] = collect(first(t) for t in tree.transitions[sa])
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
        color = weighted_color_mean(rel_q, colorant"green", colorant"red")
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
