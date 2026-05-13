from std.python import Python
from src.core.workflow_node import WorkflowNode
from src.core.hyperedge import Hyperedge
from std.collections import List

struct WorkflowParser:
    """
    Infrastructure Layer: Parses visual or JSON workflow definitions into the DHG structure.
    Implements Algorithm 1: parse(workflow) -> wfRepresentation.
    """
    
    def __init__(out self):
        pass

    def load_nodes_from_yaml(mut self, yaml_path: String) raises -> List[WorkflowNode]:
        """
        Loads only the node definitions from a YAML workflow file.
        Separated from load_edges_from_yaml to avoid Mojo Tuple return limitations.
        """
        var yaml = Python.import_module("yaml")
        var builtins = Python.import_module("builtins")
        
        print("[Parser] Loading nodes from: " + yaml_path)
        
        var f = builtins.open(yaml_path, "r")
        var data = yaml.safe_load(f)
        f.close()
        
        var nodes = List[WorkflowNode]()
        var yaml_nodes = data["nodes"]
        for i in range(len(yaml_nodes)):
            var y_node = yaml_nodes[i]
            var id: Int = atol(String(y_node["id"]))
            var name    = String(y_node["name"])
            var platform = String(y_node.get("platform", ""))
            var image    = String(y_node.get("image", ""))
            print("   -> Node " + String(id) + ": " + name +
                  " [" + platform + "] " + image)
            nodes.append(WorkflowNode(id, name))
            
        return nodes^

    def load_edges_from_yaml(mut self, yaml_path: String) raises -> List[Hyperedge]:
        """
        Parses only the hyperedge definitions from a YAML file.
        Enables the 'Hot Deployment' of workflow definitions as per Section II.A.
        """
        var yaml = Python.import_module("yaml")
        var builtins = Python.import_module("builtins")
        
        print("[Parser] Loading edges from: " + yaml_path)
        
        var f = builtins.open(yaml_path, "r")
        var data = yaml.safe_load(f)
        f.close()
        
        var edges = List[Hyperedge]()
        var yaml_edges = data["edges"]
        for i in range(len(yaml_edges)):
            var y_edge  = yaml_edges[i]
            var id: Int = atol(String(y_edge["id"]))
            var label   = String(y_edge["label"])
            var source: Int = atol(String(y_edge["source"]))
            var blocking_int: Int = atol(String(y_edge["is_blocking"]))
            var sync = blocking_int == 1
            
            var dests = List[Int]()
            var y_dests = y_edge["destinations"]
            for j in range(len(y_dests)):
                var dest: Int = atol(String(y_dests[j]))
                dests.append(dest)
                
            print("   -> Hyperedge [" + label + "]: " + String(source) + " -> destinations")
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return edges^
