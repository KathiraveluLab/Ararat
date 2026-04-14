from python import Python
from ..core.workflow_node import WorkflowNode
from ..core.hyperedge import Hyperedge
from collections import List

struct WorkflowParser:
    """
    Infrastructure Layer: Parsers visual or JSON workflow definitions into the DHG structure.
    Implements Algorithm 1: parse(workflow) -> wfRepresentation.
    """
    
    fn __init__(inout self):
        pass

    fn load_from_json(self, json_path: String) raises -> (List[WorkflowNode], List[Hyperedge]):
        """
        Loads a Software-Defined Workflow definition from a JSON file.
        Uses Python interoperability for mature JSON parsing.
        """
        let json = Python.import_module("json")
        let builtins = Python.import_module("builtins")
        
        print("[Parser] Loading workflow definition: " + json_path)
        
        # Open and load the workflow file
        let f = builtins.open(json_path, "r")
        let data = json.load(f)
        f.close()
        
        var nodes = List[WorkflowNode]()
        var edges = List[Hyperedge]()
        
        # 1. Parse Nodes
        let json_nodes = data["nodes"]
        for i in range(len(json_nodes)):
            let j_node = json_nodes[i]
            let id = j_node["id"].to_float64().to_int()
            let name = j_node["name"].to_string()
            print("   -> Parsing Node " + str(id) + ": " + name)
            nodes.append(WorkflowNode(id, name))
            
        # 2. Parse Hyperedges (DHG)
        let json_edges = data["edges"]
        for i in range(len(json_edges)):
            let j_edge = json_edges[i]
            let id = j_edge["id"].to_float64().to_int()
            let label = j_edge["label"].to_string()
            let source = j_edge["source"].to_float64().to_int()
            let sync = j_edge["is_blocking"].to_float64().to_int() == 1
            
            var dests = List[Int]()
            let j_dests = j_edge["destinations"]
            for j in range(len(j_dests)):
                dests.append(j_dests[j].to_float64().to_int())
                
            print("   -> Parsing Hyperedge [" + label + "]: Node " + str(source) + " -> multiple")
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return (nodes, edges)

    fn load_edges_from_json(self, json_path: String) raises -> List[Hyperedge]:
        """
        Parses only the hyperedge definitions from a JSON file.
        Enables the 'Hot Deployment' of workflow definitions as per Section II.A.
        """
        let json = Python.import_module("json")
        let builtins = Python.import_module("builtins")
        
        print("[Parser] Loading incremental topology: " + json_path)
        
        let f = builtins.open(json_path, "r")
        let data = json.load(f)
        f.close()
        
        var edges = List[Hyperedge]()
        let json_edges = data["edges"]
        for i in range(len(json_edges)):
            let j_edge = json_edges[i]
            let id = j_edge["id"].to_float64().to_int()
            let label = j_edge["label"].to_string()
            let source = j_edge["source"].to_float64().to_int()
            let sync = j_edge["is_blocking"].to_float64().to_int() == 1
            
            var dests = List[Int]()
            let j_dests = j_edge["destinations"]
            for j in range(len(j_dests)):
                dests.append(j_dests[j].to_float64().to_int())
                
            edges.append(Hyperedge(id, label, source, dests, sync))
            
        return edges
