
if (typeof $ === 'undefined') {
    loadScript("https://code.jquery.com/jquery-3.1.1.min.js", run)
} else {
    run()
}

function run() {
    if (typeof d3 === 'undefined') {
        loadScript("https://d3js.org/d3.v3.js", showTree)
    } else {
        showTree()
    }
}

function loadScript(url, callback)
{
    console.log("starting script load...")
    // Adding the script tag to the head as suggested before
    var head = document.getElementsByTagName('head')[0];
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = url;

    // Then bind the event to the callback function.
    // There are several events for cross browser compatibility.
    script.onreadystatechange = callback;
    script.onload = callback;

    // Fire the loading
    head.appendChild(script);
}


function showTree() {
        
    // var margin = {top: 20, right: 120, bottom: 20, left: 120},
    var margin = {top: 20, right: 120, bottom: 80, left: 120},
        width = $("#"+div).width() - margin.right - margin.left,
        height = 600 - margin.top - margin.bottom;
        // height = 600 - margin.top - margin.bottom;
        // TODO make height a parameter of TreeVisualizer

    var i = 0,
        duration = 750,
        root;

    var tree = d3.layout.tree()
        .size([width, height]);

    var diagonal = d3.svg.diagonal();
        //.projection(function(d) { return [d.y, d.x]; });
        // uncomment above to make the tree go horizontally

    // see http://stackoverflow.com/questions/16265123/resize-svg-when-window-is-resized-in-d3-js
    if (d3.select("#"+div+"_svg").empty()) {
        d3.select("#"+div).append("svg")
            .attr("id", div+"_svg")
            .attr("width", width + margin.right + margin.left)
            .attr("height", height + margin.top + margin.bottom);
            /*
            .append("div")
            .classed("svg-container", true)
            .append("svg")
                .attr("id", div+"_svg")
                .attr("preserveAspectRatio", "xMinYMin meet")
                .attr("viewBox", "0 0 "+width+" "+height)
                .classed("svg-content-responsive", true);
                */
    }

    d3.select("#"+div+"_svg").selectAll("*").remove();

    var svg = d3.select("#"+div+"_svg")
        .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    // console.log("tree data:");
    // console.log(treeData[rootID]);
    root = createDisplayNode(treeData[rootID]);
    root.x0 = width / 2;
    root.y0 = 0;

    // find maxima and minima for 
    var maxQ = 0.0;
    var minQ = 0.0;
    var maxN = 0;
    for (var id in treeData) {
      data = treeData[id];
      if (data.type=="action") {
        if (data.Q > maxQ) {
          maxQ = data.Q
        } else if (data.Q < minQ) {
          minQ = data.Q
        }
        if (data.N > maxN) {
          maxN = data.N
        }
      }
    }
    // console.log("maxN: " + maxN)

    update(root);
    console.log("tree should appear");

    function createDisplayNode(nd) {
      var dnode = {"dataID":nd.id,
                   "children":null,
                   "_children":null};
      if (nd.type=="action") {
          dnode.Q = nd.Q;
      }
      return dnode;
    }

    function initializeChildren(d) {
      // create children
      var ndata = treeData[d.dataID];
      d.children = [];
      if (ndata.children_ids) {
        for (var i = 0; i < ndata.children_ids.length; i++) {
          var id = ndata.children_ids[i];
          if (!treeData[id]) {
            alert("bad node id:"+id+" (in node "+d.dataID+")")
          } else {
              d.children.push(createDisplayNode(treeData[id]));
          }
        }
      }
    }

    function tooltip(d) {
        var data = treeData[d.dataID]
        var tt = data.tt_tag + "\n" +
        "id: " + data.id + "\n" +
        "N: " + data.N;
        if (data.type=="action") {
            tt += "\nQ: " + data.Q;
        }
        return tt;
    }
    /*
    function collapse(d) {
        if ("children" in d && d.children) {
            d._children = d.children;
            d._children.forEach(collapse);
            d.children = null;
        }
    }
    */

    function update(source) {

      width = $("#"+div).width() - margin.right - margin.left,
      height = $("#"+div).height() - margin.top - margin.bottom;

      tree.size([width,height]);
      d3.select("#"+div).attr("width", width + margin.right + margin.left)
            .attr("height", height + margin.top + margin.bottom);
      d3.select("#"+div+"_svg").attr("width", width + margin.right + margin.left)
             .attr("height", height + margin.top + margin.bottom);


      // Compute the new tree layout.
      var nodes = tree.nodes(root).reverse(),
          links = tree.links(nodes);

      // Normalize for fixed-depth.
      // nodes.forEach(function(d) { d.y = d.depth * 180; });

      /*
      var newHeight = height;
      nodes.forEach(function(d) { if (d.y > newHeight) {newHeight = d.y;} });
      svg.attr("height", height + margin.top + margin.bottom);
      */

      // Update the nodes…
      var node = svg.selectAll("g.node")
          .data(nodes, function(d) { return d.id || (d.id = ++i); });

      // Enter any new nodes at the parent's previous position.
      var nodeEnter = node.enter().append("g")
          .attr("class", "node")
          .attr("transform", function(d) { return "translate(" + source.x0 + "," + source.y0 + ")"; })
          .on("click", click);

      nodeEnter.append("circle")
          .attr("r", 1e-6)
          .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

      /*
      nodeEnter.append("text")
          .attr("x", function(d) { return d.children || d._children ? -13 : 13; })
          .attr("dy", ".35em")
          .attr("text-anchor", function(d) { return d.children || d._children ? "end" : "start"; })
          .text(function(d) { return d.tag; })
          .style("fill-opacity", 1e-6);
          */

      /*
      nodeEnter.append("text")
          .attr("y", 25)
          .attr("text-anchor", "middle")
          .text(function(d) { return d.tag + " N: " + d.N + (d.type=="action"? " Q: " + d.Q.toPrecision(4):""); })
          .style("fill-opacity", 1e-6);
          */
      var tbox = nodeEnter.append("text")
          .attr("y", 25)
          .attr("text-anchor", "middle")
          .style("fill-opacity", 1e-6);

      tbox.append("tspan")
          .text( function(d) { return treeData[d.dataID].tag; } );

      tbox.append("tspan")
          .attr("dy","1.2em")
          .attr("x",0)
          .text( function(d) {return "N:" + treeData[d.dataID].N;} );

      tbox.append("tspan")
          .attr("dy","1.2em")
          .attr("x",0)
          .text( function(d) { if (treeData[d.dataID].type=="action") {return " Q:" + treeData[d.dataID].Q.toPrecision(4);}});

      // tooltip
      nodeEnter.append("title").text(tooltip)


      // Transition nodes to their new position.
      var nodeUpdate = node.transition()
          .duration(duration)
          .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

      nodeUpdate.select("circle")
          .attr("r", 10)
          .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

      nodeUpdate.select("text")
          .style("fill-opacity", 1);

      // Transition exiting nodes to the parent's new position.
      var nodeExit = node.exit().transition()
          .duration(duration)
          .attr("transform", function(d) { return "translate(" + source.x + "," + source.y + ")"; })
          .remove();

      nodeExit.select("circle")
          .attr("r", 1e-6);

      nodeExit.select("text")
          .style("fill-opacity", 1e-6);

      // Update the links…
      var link = svg.selectAll("path.link")
          .data(links, function(d) { return d.target.id; });

      // Enter any new links at the parent's previous position.
      // XXX link width should be based on transition data, not node data
      link.enter().insert("path", "g")
          .attr("class", "link")
          .style("stroke-width", function(d) {
              return 10.0*Math.log(treeData[d.target.dataID].N+2)/Math.log(maxN) + "px";})
          .attr("d", function(d) {
            var o = {x: source.x0, y: source.y0};
            return diagonal({source: o, target: o});
          });

      // Transition links to their new position.
      link.transition()
          .duration(duration)
          .attr("d", diagonal);

      // Transition exiting nodes to the parent's new position.
      link.exit().transition()
          .duration(duration)
          .attr("d", function(d) {
            var o = {x: source.x, y: source.y};
            return diagonal({source: o, target: o});
          })
          .remove();

      // Stash the old positions for transition.
      nodes.forEach(function(d) {
        d.x0 = d.x;
        d.y0 = d.y;
      });
    }

    // Toggle children on click.
    function click(d) {
      // console.log("clicked");
      if (d.children) {
        d._children = d.children;
        d.children = null;
      } else if (d._children) {
        d.children = d._children;
        d._children = null;
      } else {
        initializeChildren(d);
      }
      update(d);
    }

}
