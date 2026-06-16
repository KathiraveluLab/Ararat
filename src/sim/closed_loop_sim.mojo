from src.core.workflow_node import WorkflowNode
from src.core.hyperedge import Hyperedge
from src.controller.sdn import AraratOrchestrator
from src.infra.parser import WorkflowParser
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
    orchestrator.initialize_workflow(nodes^, edges^)
    
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
    
    var nodes = parser.load_nodes_from_yaml("workflows/neuromodulation.yaml")
    var edges = parser.load_edges_from_yaml("workflows/neuromodulation.yaml")
    
    orchestrator.initialize_workflow(nodes^, edges^)
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
    var init_nodes = parser.load_nodes_from_yaml("workflows/neuromodulation.yaml")
    var init_edges = parser.load_edges_from_yaml("workflows/neuromodulation.yaml")
    orchestrator.initialize_workflow(init_nodes^, init_edges^)
    
    print("\n>> Phase 1: Standard Synchronous Control Flow")
    orchestrator.orchestrate_pass()
    
    # 2. Hot-Swap Event (Injected via Control Plane)
    var new_edges = parser.load_edges_from_yaml("workflows/dynamic_update.yaml")
    orchestrator.update_topology(new_edges^)
    
    print("\n>> Phase 2: Post-Update Control Flow (Asynchronous Signaling)")
    orchestrator.orchestrate_pass()

def run_neo4j_sim():
    """
    Demonstrates the database-driven Neo4jOrchestrator.
    Attempts to connect to a local Neo4j database, initializes a sample
    Directed Hypergraph (DHG) topology, and runs a stateless query execution loop.
    If Neo4j is not reachable, it fails gracefully with setup instructions.
    """
    print("\n=== Neo4j-Native Database-Driven Simulation ===")
    from src.controller.neo4j_orchestrator import Neo4jOrchestrator
    try:
        var orchestrator = Neo4jOrchestrator("bolt://localhost:7687", "neo4j", "password")
        
        # Set up a sample topology
        var session = orchestrator.driver.session()
        print("   [Simulator] Initializing general-purpose workflow in Neo4j...")
        
        # Clear existing
        session.run("MATCH (n) DETACH DELETE n")
        
        # Create ServiceNodes
        session.run("CREATE (n:ServiceNode {id: 0, name: 'Sensing Node', platform: 'local', image: 'scripts/bayesian_optimizer.py', status: 'PENDING'})")
        session.run("CREATE (n:ServiceNode {id: 1, name: 'Controller Node', platform: 'local', image: 'scripts/bayesian_optimizer.py', status: 'PENDING'})")
        
        # Create Hyperedges
        session.run("CREATE (e:Hyperedge {id: 10, label: 'DATA_STREAM', status: 'IDLE', is_blocking: true})")
        session.run("CREATE (e:Hyperedge {id: 11, label: 'CONTROL_FEEDBACK', status: 'IDLE', is_blocking: true})")
        
        # Connect outflow/inflow
        session.run("MATCH (src:ServiceNode {id: 0}), (edge:Hyperedge {id: 10}), (dst:ServiceNode {id: 1}) CREATE (src)-[:OUTFLOW]->(edge), (edge)-[:INFLOW]->(dst)")
        session.run("MATCH (src:ServiceNode {id: 1}), (edge:Hyperedge {id: 11}), (dst:ServiceNode {id: 0}) CREATE (src)-[:OUTFLOW]->(edge), (edge)-[:INFLOW]->(dst)")
        
        session.close()
        
        # Check for loops/cycles in the workflow template
        print("   [Simulator] Running cycle detection algorithm...")
        _ = orchestrator.check_cycles()
        
        # Run a few loops
        for i in range(2):
            print("\n   --- Neo4j Loop Iteration " + String(i + 1) + " ---")
            orchestrator.run_orchestration_loop()
            
        # Mocking a service node failure to show transitive downstream dependency pruning in action
        print("\n   [Simulator] Mocking failure on Node 0 to trigger downstream path pruning...")
        var prune_session = orchestrator.driver.session()
        orchestrator.prune_downstream(prune_session, 0)
        prune_session.close()
            
        orchestrator.close()
    except:
        print("   [Simulator] Neo4j is not reachable at bolt://localhost:7687.")
        print("   [Simulator] To run this demo, start a local Neo4j instance:")
        print("       docker run -d --name neo4j -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/password neo4j:latest")

def main() raises:
    run_neuromodulation_sim()
    run_yaml_driven_sim()
    run_hot_swap_sim()
    run_neo4j_sim()

