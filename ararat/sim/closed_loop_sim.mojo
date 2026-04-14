from ..core.workflow_node import WorkflowNode
from ..core.hyperedge import Hyperedge
from ..controller.sdn import AraratOrchestrator
from collections import List

fn run_neuromodulation_sim():
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
    nodes.append(pm_node)
    nodes.append(ctl_node)
    
    # 2. Directed Hypergraph Definition (Equation 2: W = A -> B -> ... )
    # In this closed-loop, PM sends data to CTL, and CTL provides feedback to PM.
    
    # Hyperedge 1: PM -> {CTL} (Synchronous)
    var e1_dests = List[Int]()
    e1_dests.append(1)
    let e1 = Hyperedge(1, "NEURAL_RECORDING", 0, e1_dests, True)
    
    # Hyperedge 2: CTL -> {PM} (Synchronous Feedback Loop)
    var e2_dests = List[Int]()
    e2_dests.append(0)
    let e2 = Hyperedge(2, "STIMULATION_PARAMS", 1, e2_dests, True)
    
    var edges = List[Hyperedge]()
    edges.append(e1)
    edges.append(e2)
    
    # 3. SDW Orchestration Initialization
    orchestrator.initialize_workflow(nodes, edges)
    
    # 4. Simulation Execution: 20 Iterations (Standard evaluation size in paper)
    orchestrator.run_simulation(20)

fn main():
    run_neuromodulation_sim()
