import JSON
import Base: writemime

# put your policy in one of these to automatically visualize it in a python notebook
type TreeVisualizer{PolicyType}
    policy::PolicyType
    init_state
end

node_tag(s) = string(s)
tooltip_tag(s) = node_tag(s)

function create_json{P<:AbstractMCTSPolicy}(visualizer::TreeVisualizer{P})
    local root_id
    next_id = 1
    node_dict = Dict{Int, Dict{UTF8String, Any}}()
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

    # go back and refill action nodes
    for (s, sn) in visualizer.policy.tree
        for san in sn.sanodes
            a = san.action
            for sp in san._vis_stats
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

function create_json(visualizer::TreeVisualizer{DPWPolicy})
    local root_id
    next_id = 1
    node_dict = Dict{Int, Dict{UTF8String, Any}}()
    s_dict = Dict{Any, Int}()
    sa_dict = Dict{Any, Int}()
    for (s, sn) in visualizer.policy.T
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

    # go back and refill action nodes
    for (s, sn) in visualizer.policy.T
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

function writemime(f::IO, ::MIME"text/html", visualizer::TreeVisualizer)
    json, root_id = create_json(visualizer)
    # write("/tmp/tree_dump.json", json)
    css = readall(joinpath(dirname(@__FILE__()), "tree_vis.css"))
    js = readall(joinpath(dirname(@__FILE__()), "tree_vis.js"))
    div = "trevis$(randstring())"

    html_string = """
        <div id="$div">
        <style>
            $css
        </style>
        <script src="http://d3js.org/d3.v3.js"></script>
        <script>
            var treeData = $json;
            var rootID = $root_id;
            var div = "#$div";
            $js
        </script>
        </div>
    """
    # html_string = "visualization doesn't work yet :("

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
