import JSON

# put your policy in one of these to automatically visualize it in a python notebook
type TreeVisualizer{PolicyType}
    policy::PolicyType
    init_state
end

"""
Return text to display below the node corresponding to state or action s
"""
node_tag(s) = string(s)

"""
Return text to display in the tooltip for the node corresponding to state or action s
"""
tooltip_tag(s) = node_tag(s)

function create_json{P<:AbstractMCTSPolicy}(visualizer::TreeVisualizer{P})
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

function create_json{P<:DPWPolicy}(visualizer::TreeVisualizer{P})
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

# function stringmime(m::MIME"text/html", visualizer::TreeVisualizer)
function Base.show(f::IO, m::MIME"text/html", visualizer::TreeVisualizer)
    json, root_id = create_json(visualizer)
    # write("/tmp/tree_dump.json", json)
    css = @compat readstring(joinpath(dirname(@__FILE__()), "tree_vis.css"))
    js = @compat readstring(joinpath(dirname(@__FILE__()), "tree_vis.js"))
    div = "treevis$(randstring())"

    html_string = """
        <div id="$div">
        <style>
            $css
        </style>
        <script>
           (function(){
            var treeData = $json;
            var rootID = $root_id;
            var div = "$div";
            $js
            })();
        </script>
        </div>
    """
    # html_string = "visualization doesn't work yet :("

    # <script src="http://d3js.org/d3.v3.js"></script>

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
