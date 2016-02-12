
// ************** Generate the tree diagram	 *****************
// var margin = {top: 20, right: 120, bottom: 20, left: 120},
var margin = {top: 20, right: 120, bottom: 80, left: 120},
	width = $("#treevis").width() - margin.right - margin.left,
    height = 600 - margin.top - margin.bottom;
    // TODO make height a parameter of TreeVisualizer
	
var i = 0,
	duration = 750,
	root;

var tree = d3.layout.tree()
	.size([width, height]);

var diagonal = d3.svg.diagonal();
	//.projection(function(d) { return [d.y, d.x]; });
    // uncomment above to make the tree go horizontally

var svg = d3.select("#treevis").append("svg")
	.attr("width", width + margin.right + margin.left)
	.attr("height", height + margin.top + margin.bottom)
  .append("g")
	.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

console.log("tree data:");
console.log(treeData[rootID]);
root = createDisplayNode(treeData[rootID]);
root.x0 = width / 2;
root.y0 = 0;
update(root);
console.log("tree should appear");

function createDisplayNode(nd) {
  var dnode = {"dataID":nd.id,
               "children":null,
               "_children":null,
               "tag":nd.tag,
               "type":nd.type,
               "N":nd.N};
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
    var tt = d.tag + "\n" +
    "id: " + d.dataID + "\n" +
    "N: " + d.N;
    if (d.type=="action") {
        tt += "\nQ: " + d.Q;
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
      .text( function(d) { return d.tag; } );

  tbox.append("tspan")
      .attr("dy","1.2em")
      .attr("x",0)
      .text( function(d) {return "N:" + d.N;} );

  tbox.append("tspan")
      .attr("dy","1.2em")
      .attr("x",0)
      .text( function(d) { if (d.type=="action") {return " Q:" + d.Q.toPrecision(4);}});

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
  link.enter().insert("path", "g")
	  .attr("class", "link")
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
  console.log("clicked");
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
