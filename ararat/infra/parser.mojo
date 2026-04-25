from std.python import Python
from ararat.core.workflow_node import WorkflowNode
from ararat.core.hyperedge import Hyperedge
from std.collections import List

struct WorkflowParser:
    """
    Infrastructure Layer: Parsers visual or JSON workflow definitions into the DHG structure.
    Implements Algorithm 1: parse(workflow) -> wfRepresentation.
    """
    
    def __init__(out self):
        pass

    def load_from_yaml(mut self, yaml_path: String) raises -> (List[WorkflowNode], List[Hyperedge]):
        """
        Loads a Software-Defined Workflow definition from a YAML file.
        Uses Python interoperability for mature YAML parsing.
        """
        var yaml = Python.import_module("yaml")
        var builtins = Python.import_module("builtins")
        
        print("[Parser] Loading workflow definition: " + yaml_path)
        
        # Open and load the workflow file
        var f = builtins.open(yaml_path, "r")
        var data = yaml.safe_load(f)
        f.close()
        
        var nodes = List[WorkflowNode]()
        var edges = List[Hyperedge]()
        
        # 1. Parse Nodes
        var yaml_nodes = data["nodes"]
        for i in range(len(yaml_nodes)):
            var y_node = yaml_nodes[i]
            var id = y_node["id"].to_float64().to_int()
            var name = y_node["name"].to_string()
            print("   -> Parsing Node " + String(id) + ": " + name)
            nodes.append(WorkflowNode(id, name))
            
        # 2. Parse Hyperedges (DHG)
        var yaml_edges = data["edges"]
        for i in range(len(yaml_edges)):
            var y_edge = yaml_edges[i]
            var id = y_edge["id"].to_float64().to_int()
            var label = y_edge["label"].to_string()
            var source = y_edge["source"].to_float64().to_int()
            var sync = y_edge["is_blocking"].to_float64().to_int() == 1
            
            var dests = List[Int]()
            var y_dests = y_edge["destinations"]
            for j in range(len(y_dests)):
                dests.append(y_dests[j].to_float64().to_int())
                
            print("   -> Parsing Hyperedge [" + label + "]: Node " + String(source) + " -> multiple")
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return (nodes, edges)

    def load_edges_from_yaml(mut self, yaml_path: String) raises -> List[Hyperedge]:
        """
        Parses only the hyperedge definitions from a YAML file.
        Enables the 'Hot Deployment' of workflow definitions as per Section II.A.
        """
        var yaml = Python.import_module("yaml")
        var builtins = Python.import_module("builtins")
        
        print("[Parser] Loading incremental topology: " + yaml_path)
        
        var f = builtins.open(yaml_path, "r")
        var data = yaml.safe_load(f)
        f.close()
        
        var edges = List[Hyperedge]()
        var yaml_edges = data["edges"]
        for i in range(len(yaml_edges)):
            var y_edge = yaml_edges[i]
            var id = y_edge["id"].to_float64().to_int()
            var label = y_edge["label"].to_string()
            var source = y_edge["source"].to_float64().to_int()
            var sync = y_edge["is_blocking"].to_float64().to_int() == 1
            
            var dests = List[Int]()
            var y_dests = y_edge["destinations"]
            for j in range(len(y_dests)):
                dests.append(y_dests[j].to_float64().to_int())
                
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return edges
