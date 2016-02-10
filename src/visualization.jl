import JSON

# put your policy in one of these to automatically visualize it in a python notebook
type TreeVisualizer{PolicyType}
    policy::PolicyType
    init_state
end

function create_json(visualizer::TreeVisualizer{MCTSPolicy})
    local root_id
    next_id = 1
    node_dict = Dict{Int,Dict{UTF8String, Any}}()
    for (s, sn) in visualizer.policy.mcts.tree
        children = Vector(Int,0)
        for (i,a) in enumerate(visualizer.policy.action_map)
            if sn.n[i] > 0
                node_dict[next_id]
                next_id += 1
            end
        end
        node_dict[next_id] = Dict("children"=>children,
                                  "info"=>"$s | N:$(sum(sn.n))"
                                 ) 
        if s == visualizer.init_state
            root_id = next_id 
        end
        next_id += 1
    end
    JSON.json
    return json, root_id
end

function Base.writemime(f::IO, ::MIME"text/html", visualizer::TreeVisualizer{MCTSPolicy})
    json, root_id = create_json(visualizer)
    css = readall(joinpath(dirname(@__FILE__()), "tree_vis.css"))
    js = readall(joinpath(dirname(@__FILE__()), "tree_vis.js"))

    #=
    html_string = """
        <div id="treevis">
        <style>
            $css
        </style>
        <script src="http://d3js.org/d3.v3.min.js"></script>
        <script>
            var treeData = [$json];
            var rootID = $root_id;
            $js
        </script>
        </div>
    """
    =#

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
