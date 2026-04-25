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

    def load_from_json(mut self, json_path: String) raises -> (List[WorkflowNode], List[Hyperedge]):
        """
        Loads a Software-Defined Workflow definition from a JSON file.
        Uses Python interoperability for mature JSON parsing.
        """
        var json = Python.import_module("json")
        var builtins = Python.import_module("builtins")
        
        print("[Parser] Loading workflow definition: " + json_path)
        
        # Open and load the workflow file
        var f = builtins.open(json_path, "r")
        var data = json.load(f)
        f.close()
        
        var nodes = List[WorkflowNode]()
        var edges = List[Hyperedge]()
        
        # 1. Parse Nodes
        var json_nodes = data["nodes"]
        for i in range(len(json_nodes)):
            var j_node = json_nodes[i]
            var id = j_node["id"].to_float64().to_int()
            var name = j_node["name"].to_string()
            print("   -> Parsing Node " + String(id) + ": " + name)
            nodes.append(WorkflowNode(id, name))
            
        # 2. Parse Hyperedges (DHG)
        var json_edges = data["edges"]
        for i in range(len(json_edges)):
            var j_edge = json_edges[i]
            var id = j_edge["id"].to_float64().to_int()
            var label = j_edge["label"].to_string()
            var source = j_edge["source"].to_float64().to_int()
            var sync = j_edge["is_blocking"].to_float64().to_int() == 1
            
            var dests = List[Int]()
            var j_dests = j_edge["destinations"]
            for j in range(len(j_dests)):
                dests.append(j_dests[j].to_float64().to_int())
                
            print("   -> Parsing Hyperedge [" + label + "]: Node " + String(source) + " -> multiple")
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return (nodes, edges)

    def load_edges_from_json(mut self, json_path: String) raises -> List[Hyperedge]:
        """
        Parses only the hyperedge definitions from a JSON file.
        Enables the 'Hot Deployment' of workflow definitions as per Section II.A.
        """
        var json = Python.import_module("json")
        var builtins = Python.import_module("builtins")
        
        print("[Parser] Loading incremental topology: " + json_path)
        
        var f = builtins.open(json_path, "r")
        var data = json.load(f)
        f.close()
        
        var edges = List[Hyperedge]()
        var json_edges = data["edges"]
        for i in range(len(json_edges)):
            var j_edge = json_edges[i]
            var id = j_edge["id"].to_float64().to_int()
            var label = j_edge["label"].to_string()
            var source = j_edge["source"].to_float64().to_int()
            var sync = j_edge["is_blocking"].to_float64().to_int() == 1
            
            var dests = List[Int]()
            var j_dests = j_edge["destinations"]
            for j in range(len(j_dests)):
                dests.append(j_dests[j].to_float64().to_int())
                
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return edges
