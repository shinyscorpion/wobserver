function process_to_node(process) {
  return {
    HTMLclass: process.meta.class,
    text: {
      name: process.name.replace(/^Elixir\./, ''),
      title: process.pid
    },
    meta: {
        process
    },
    children: process.children.map(process_to_node)
  };
}

const ApplicationGraph = {
  show: (application, graph_id) => {
    var structure = process_to_node(application);

    var tree_structure = {
      chart: {
        container:   "#" + graph_id,
        rootOrientation:  "WEST",
        levelSeparation:    30,
        siblingSeparation:  15,
        subTeeSeparation:   25,

        node: {
          HTMLclass: 'process-node',
          drawLineThrough: false
        },
        connectors: {
          type: "straight",
          style: {
              "stroke-width": 2,
              "stroke": "#ccc"
          }
        }
      },

      nodeStructure: structure
    }

    new Treant( tree_structure );
  }
}

export{ ApplicationGraph }
