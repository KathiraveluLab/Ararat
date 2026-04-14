from ..core.workflow_node import WorkflowNode
from ..core.hyperedge import Hyperedge
from ..infra.launcher import ServiceLauncher
from collections import List, Dict

struct AraratOrchestrator:
    """
    Logically centralized controller for Software-Defined Workflows (SDW).
    Manages the Control Plane and orchestrates events across the Directed Hypergraph (DHG).
    """
    var nodes: List[WorkflowNode]
    var hyperedges: List[Hyperedge]
    var launcher: ServiceLauncher
    
    fn __init__(inout self):
        self.nodes = List[WorkflowNode]()
        self.hyperedges = List[Hyperedge]()
        self.launcher = ServiceLauncher()
        
    fn initialize_workflow(inout self, nodes: List[WorkflowNode], edges: List[Hyperedge]):
        """
        Algorithm 1: Parse and set the workflow representation.
        Initializes the control plane state for all service nodes.
        """
        print("[Orchestrator] Initializing Ararat Workflow...")
        self.nodes = nodes
        self.hyperedges = edges
        
        # Algorithm 1: serviceInit for all nodes
        for i in range(len(self.nodes)):
            print("   -> Initializing Service Agent at Node " + str(self.nodes[i].id) + ": " + self.nodes[i].name)

    fn emit_control_event(self, node_id: Int, event: String):
        """
        Emulates the RESTful control events sent via the Northbound interface.
        Decouples control from the data-plane execution.
        """
        print("   [Control Event] Node " + str(node_id) + " :: " + event)

    fn update_topology(inout self, new_edges: List[Hyperedge]):
        """
        Section II.A: 'hot deployment of workflow definitions by managing and propagating the control'.
        Allows the Orchestrator to re-route data flows without process restart.
        """
        print("\n[Control Plane] !!! HOT-SWAPPING WORKFLOW TOPOLOGY !!!")
        self.hyperedges = new_edges
        for i in range(len(self.hyperedges)):
            print("   -> New Path Active: " + self.hyperedges[i].label)

    fn run_simulation(inout self, iterations: Int):
        """
        Executes the closed-loop workflow for N iterations as defined in Equation 2.
        """
        print("\n" + "="*40)
        print(" Ararat SOFTWARE-DEFINED WORKFLOW ENGINE")
        print("="*40)
        print("Topology: Directed Hypergraph (DHG)")
        print("Loops: Cycles supported via iterative orchestration")
        
        for i in range(iterations):
            print("\n--- [Global Iteration " + str(i + 1) + "] ---")
            
            # Hot-Swap Simulation: at iteration 3, we update the topology
            if i == 2:
                # This would normally be triggered by a Northbound REST event
                print("   [Trigger] Dynamic update event received from Northbound API...")
            
            self.orchestrate_pass()
            
        print("\n" + "="*40)
        print(" WORKFLOW COMPLETED SUCCESSFULLY")
        print("="*40)

    fn orchestrate_pass(inout self):
        """
        Orchestrates Algorithm 2: Service Executions across the DHG.
        Supports both Synchronous (Blocking) and Asynchronous (Thin) hyperedges.
        """
        for i in range(len(self.nodes)):
            var node = self.nodes[i]
            
            # 1. Trigger service via control plane
            self.emit_control_event(node.id, "TRIGGER_EXECUTION")
            
            # 2. Invoke Data Plane Service
            let dummy_input = Dict[String, Float64]()
            let output = node.process(dummy_input)
            
            # 3. Propagate output through Hyperedges (Respecting Synchronicity)
            self._propagate_data(node.id, output)

    fn _propagate_data(self, source_id: Int, data: Dict[String, Float64]):
        """
        Finds all hyperedges where source_id is the origin and signals destinations.
        Implements Section III.A Synchronous/Asynchronous variants.
        """
        for i in range(len(self.hyperedges)):
            let edge = self.hyperedges[i]
            if edge.source_id == source_id:
                if edge.is_blocking:
                    print("   [Sync Signal] Blocking until ACK from destinations of " + edge.label)
                else:
                    print("   [Async Signal] Fire-and-forget update via Thin Edge " + edge.label)
                
                edge.display()
                for j in range(len(edge.destination_ids)):
                    self.emit_control_event(edge.destination_ids[j], "DATA_AVAILABLE")
