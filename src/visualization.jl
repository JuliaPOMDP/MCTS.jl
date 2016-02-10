import JSON

# put your policy in one of these to automatically visualize it in a python notebook
type TreeVisualizer{PolicyType}
    policy::PolicyType
    init_state
end

function create_json(visualizer::TreeVisualizer{DPWPolicy})
    local root_id
    next_id = 1
    node_dict = Dict{Int, Dict{UTF8String, Any}}()
    s_dict = Dict{Any, Int}()
    sa_dict = Dict{Any, Int}()
    for (s, sn) in visualizer.policy.T
        # create state node
        node_dict[next_id] = sd = Dict("type"=>:state,
                                       "children"=>Array(Int,0),
                                       "info"=>"$s | N:$(sn.N)") 
        if s == visualizer.init_state
            root_id = next_id 
        end
        s_dict[s] = next_id
        next_id += 1

        # create action nodes
        for (a, san) in sn.A
            node_dict[next_id] = Dict("type"=>:action,
                                      "children"=>Array(Int,0),
                                      "info"=>"$a | N:$(san.N), Q:$(@sprintf("%.2g", san.Q))")
            push!(sd["children"], next_id)
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
                    push!(sad["children"], s_dict[sp])
                else
                    node_dict[next_id] = Dict("type"=>:state,
                                              "children"=>Array(Int,0),
                                              "info"=>"$s | N:0") 
                    push!(sad["children"], next_id)
                end
            end
        end
    end
    json = JSON.json(node_dict)
    return (json, root_id)
end

function Base.writemime(f::IO, ::MIME"text/html", visualizer::TreeVisualizer{DPWPolicy})
    json, root_id = create_json(visualizer)
    println(json)
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
    html_string = "woo!"

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
