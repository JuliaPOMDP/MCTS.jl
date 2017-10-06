using D3Trees

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

D3Trees.D3Tree(policy::DPWPlanner, root_state; kwargs...) = D3Tree(policy.tree, root_state; kwargs...)

function D3Trees.D3Tree(tree::Dict, root_state; title="MCTS tree")
    next_id = 1
    node_dict = Dict{Int, Dict{String, Any}}()
    s_dict = Dict{Any, Int}()
    sa_dict = Dict{Any, Int}()
    for (s, sn) in visualizer.policy.tree
        if s == visualizer.init_state
            this_id = 1
        else
            this_id = next_id
        end
        # create state node
        node_dict[this_id] = sd = Dict("id"=>this_id,
                                       "type"=>:state,
                                       "children_ids"=>Array(Int,0),
                                       "tag"=>node_tag(s),
                                       "tt_tag"=>tooltip_tag(s),
                                       "N"=>sn.N
                                       )
        s_dict[s] = this_id
        if this_id == next_id
            next_id += 1
        end

        # create action nodes
        for san in sn.sanodes
            a = san.action
            node_dict[next_id] = Dict("id"=>next_id,
                                      "type"=>:action,
                                      "children_ids"=>Array(Int,0),
                                      "tag"=>node_tag(a),
                                      "tt_tag"=>tooltip_tag(a),
                                      "N"=>san.N,
                                      "Q"=>san.Q
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
    for (s, sn) in visualizer.policy.tree
        for san in sn.sanodes
            a = san.action
            for sp in get(san._vis_stats)
                sad = node_dict[sa_dict[(s,a)]]
                if haskey(s_dict, sp)
                    push!(sad["children_ids"], s_dict[sp])
                else
                    node_dict[next_id] = Dict("id"=>next_id,
                                       "type"=>:state,
                                       "children_ids"=>Array(Int,0),
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

    return D3Tree(node_dict)
end

function D3Trees.D3Tree(::Dict{Int, Dict{String, Any}})
    for 
end

#=
    lens = length(tree)
    children = Vector{Int}[]
    text = String[]
    tooltip = String[]
    style = String[]
    link_style = String[]

    next_sa_id = lens + 1
    sa_ids = Dict{Any, Int}()

    snode = tree[root_state]

    for (s, snode) in tree
        if isequal(s, root_state)
            continue
        end
        
        # info for stat node

        for san in snode.sanodes
            a = s

    end

    return D3Tree(children,
                  text=text,
                  tooltip=tooltip,
                  style=style,
                  link_style=link_style
                 )
end

struct NodeInfo
    children::Vector{Int}
    text::String
    tooltip::String
    style::String
    link_style::String
end

function state_node_info(snode, sa_ids::Dict, next_sa_id::Int)
    children = Int[]
end

function create_json{P<:AbstractMCTSPlanner}(visualizer::TreeVisualizer{P})
    # check to see if visualization was enabled
    if !visualizer.policy.solver.enable_tree_vis
        error("""
                Tree visualization was not enabled for this policy.

                Construct the solver with $(typeof(visualizer.policy.solver))(enable_tree_vis=true, ...) to enable.
            """)
    end

    root_id = -1
    next_id = 1
    node_dict = Dict{Int, Dict{String, Any}}()
    s_dict = Dict{Any, Int}()
    sa_dict = Dict{Any, Int}()
    for (s, sn) in visualizer.policy.tree
        # create state node
        node_dict[next_id] = sd = Dict("id"=>next_id,
                                       "type"=>:state,
                                       "children_ids"=>Array(Int,0),
                                       "tag"=>node_tag(s),
                                       "tt_tag"=>tooltip_tag(s),
                                       "N"=>sn.N
                                       )
        if s == visualizer.init_state
            root_id = next_id
        end
        s_dict[s] = next_id
        next_id += 1

        # create action nodes
        for san in sn.sanodes
            a = san.action
            node_dict[next_id] = Dict("id"=>next_id,
                                      "type"=>:action,
                                      "children_ids"=>Array(Int,0),
                                      "tag"=>node_tag(a),
                                      "tt_tag"=>tooltip_tag(a),
                                      "N"=>san.N,
                                      "Q"=>san.Q
                                      )
            push!(sd["children_ids"], next_id)
            sa_dict[(s,a)] = next_id
            next_id += 1
        end
    end

    if root_id < 0
        error("""
                MCTS tree visualization: Policy does not have a node for the specified state.
            """)
    end

    # go back and refill action nodes
    for (s, sn) in visualizer.policy.tree
        for san in sn.sanodes
            a = san.action
            for sp in get(san._vis_stats)
                sad = node_dict[sa_dict[(s,a)]]
                if haskey(s_dict, sp)
                    push!(sad["children_ids"], s_dict[sp])
                else
                    node_dict[next_id] = Dict("id"=>next_id,
                                       "type"=>:state,
                                       "children_ids"=>Array(Int,0),
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
    json = JSON.json(node_dict)
    return (json, root_id)
end
=#

function create_json{P<:DPWPlanner}(visualizer::TreeVisualizer{P})
    root_id = -1
    next_id = 1
    node_dict = Dict{Int, Dict{String, Any}}()
    s_dict = Dict{Any, Int}()
    sa_dict = Dict{Any, Int}()
    for (s, sn) in visualizer.policy.tree
        # create state node
        node_dict[next_id] = sd = Dict("id"=>next_id,
                                       "type"=>:state,
                                       "children_ids"=>Array(Int,0),
                                       "tag"=>node_tag(s),
                                       "tt_tag"=>tooltip_tag(s),
                                       "N"=>sn.N
                                       )
        if s == visualizer.init_state
            root_id = next_id
        end
        s_dict[s] = next_id
        next_id += 1

        # create action nodes
        for (a, san) in sn.A
            node_dict[next_id] = Dict("id"=>next_id,
                                      "type"=>:action,
                                      "children_ids"=>Array(Int,0),
                                      "tag"=>node_tag(a),
                                      "tt_tag"=>tooltip_tag(a),
                                      "N"=>san.N,
                                      "Q"=>san.Q
                                      )
            push!(sd["children_ids"], next_id)
            sa_dict[(s,a)] = next_id
            next_id += 1
        end
    end

    if root_id < 0
        error("""
                MCTS tree visualization: Policy does not have a node for the specified state.
            """)
    end


    # go back and refill action nodes
    for (s, sn) in visualizer.policy.tree
        for (a, san) in sn.A
            for (sp, sasn) in san.V
                sad = node_dict[sa_dict[(s,a)]]
                if haskey(s_dict, sp)
                    push!(sad["children_ids"], s_dict[sp])
                else
                    node_dict[next_id] = Dict("id"=>next_id,
                                       "type"=>:state,
                                       "children_ids"=>Array(Int,0),
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
    json = JSON.json(node_dict)
    return (json, root_id)
end
