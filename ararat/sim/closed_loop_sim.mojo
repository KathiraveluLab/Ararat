from ararat.core.workflow_node import WorkflowNode
from ararat.core.hyperedge import Hyperedge
from ararat.controller.sdn import AraratOrchestrator
from ararat.infra.parser import WorkflowParser
from std.collections import List

def run_neuromodulation_sim():
    """
    Executes the Neuromodulation Control System simulation from Ararat.pdf.
    Features a closed-loop interaction between a Plant Model (PM) and a Controller (CTL)
    represented as a Directed Hypergraph (DHG).
    """
    var orchestrator = AraratOrchestrator()
    
    # 1. Component Definition (Algorithm 1)
    var pm_node = WorkflowNode(0, "Plant Model (PM)")
    var ctl_node = WorkflowNode(1, "Bayesian Optimizer (CTL)")
    
    # Initialize stateful context (Algorithm 2: contextualVariables)
    pm_node.update_context("gamma_band_power", 0.05)
    ctl_node.update_context("stimulation_frequency", 60.0) # Hz
    ctl_node.update_context("stimulation_amplitude", 1.0)  # mA
    
    var nodes = List[WorkflowNode]()
    nodes.append(pm_node^)
    nodes.append(ctl_node^)
    
    # 2. Directed Hypergraph Definition (Equation 2: W = A -> B -> ... )
    # In this closed-loop, PM sends data to CTL, and CTL provides feedback to PM.
    
    # Hyperedge 1: PM -> {CTL} (Synchronous)
    var e1_dests = List[Int]()
    e1_dests.append(1)
    var e1 = Hyperedge(1, "NEURAL_RECORDING", 0, e1_dests, True)
    
    # Hyperedge 2: CTL -> {PM} (Synchronous Feedback Loop)
    var e2_dests = List[Int]()
    e2_dests.append(0)
    var e2 = Hyperedge(2, "STIMULATION_PARAMS", 1, e2_dests, True)
    
    var edges = List[Hyperedge]()
    edges.append(e1^)
    edges.append(e2^)
    
    # 3. SDW Orchestration Initialization
    orchestrator.initialize_workflow(nodes, edges)
    
    # 4. Simulation Execution: 20 Iterations (Standard evaluation size in paper)
    orchestrator.run_simulation(20)

def run_yaml_driven_sim() raises:
    """
    Demonstrates full parity by loading a DHG from a YAML definition
    and orchestrating it via the Ararat Control Plane.
    """
    print("\n[Simulator] Initializing YAML-driven Workflow...")
    var parser = WorkflowParser()
    var orchestrator = AraratOrchestrator()
    
    var workflow_data = parser.load_from_yaml("workflows/neuromodulation.yaml")
    var nodes = workflow_data.0
    var edges = workflow_data.1
    
    orchestrator.initialize_workflow(nodes, edges)
    orchestrator.run_simulation(5)

def run_hot_swap_sim() raises:
    """
    Demonstrates 100% research parity by performing a mid-run topology update.
    Implements Section II.A: 'hot deployment of workflow definitions'.
    """
    print("\n" + "#"*40)
    print(" [Simulator] STARTING DYNAMIC HOT-SWAP BENCHMARK")
    print("#"*40)
    
    var parser = WorkflowParser()
    var orchestrator = AraratOrchestrator()
    
    # 1. Initial Load (Synchronous DHG)
    var initial_data = parser.load_from_yaml("workflows/neuromodulation.yaml")
    orchestrator.initialize_workflow(initial_data.0, initial_data.1)
    
    print("\n>> Phase 1: Standard Synchronous Control Flow")
    orchestrator.orchestrate_pass()
    
    # 2. Hot-Swap Event (Injected via Control Plane)
    var new_edges = parser.load_edges_from_yaml("workflows/dynamic_update.yaml")
    orchestrator.update_topology(new_edges)
    
    print("\n>> Phase 2: Post-Update Control Flow (Asynchronous Signaling)")
    orchestrator.orchestrate_pass()

def main() raises:
    run_neuromodulation_sim()
    run_yaml_driven_sim()
    run_hot_swap_sim()
