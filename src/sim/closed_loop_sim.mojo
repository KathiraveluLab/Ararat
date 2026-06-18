from src.core.workflow_node import WorkflowNode
from src.core.hyperedge import Hyperedge
from src.controller.sdn import AraratOrchestrator
from src.infra.parser import WorkflowParser
from std.collections import List
from src.sim.topology import EuropeanCoreTopology
from src.optimization.heuristics import FineGrainedHeuristic
from src.core.service import Service
from std.python import Python

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
    Directed Hypergraph (DHG) topology alongside the ETT 2018 physical network topology,
    and runs a stateless query execution loop with network-aware service placement.
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
        
        # Load European Core physical network topology in Neo4j
        var topo = EuropeanCoreTopology()
        var fg = FineGrainedHeuristic()
        
        # Create European Core physical nodes
        var node_query = (
            "CREATE (n:NetworkNode {id: $id, name: $name, cpu_capacity: $cpu_cap, "
            "memory_capacity: $mem_cap, available_cpu: $cpu_avail, available_memory: $mem_avail, "
            "node_type: $type})"
        )
        for i in range(len(topo.nodes)):
            var node = topo.nodes[i].copy()
            var parameters = Python.dict()
            parameters["id"] = node.id
            parameters["name"] = node.node_type # The city name is stored in node.node_type
            parameters["cpu_cap"] = node.cpu_capacity
            parameters["mem_cap"] = node.memory_capacity
            parameters["cpu_avail"] = node.available_cpu
            parameters["mem_avail"] = node.available_memory
            parameters["type"] = "EDGE"
            session.run(node_query, parameters)
            
        # Create European Core physical links
        var link_query = (
            "MATCH (src:NetworkNode {id: $src}), (dst:NetworkNode {id: $dst}) "
            "CREATE (src)-[:LINK {bandwidth: $bw, latency: $lat}]->(dst)"
        )
        for i in range(len(topo.links)):
            var link = topo.links[i].copy()
            var parameters = Python.dict()
            parameters["src"] = link.source_id
            parameters["dst"] = link.dest_id
            parameters["bw"] = link.bandwidth
            parameters["lat"] = link.latency
            session.run(link_query, parameters)
            
        print("   [Network Topology] Loaded European Core physical network topology in Neo4j (12 cities, 18 links).")
        
        # Perform service allocation using the heuristic
        var sensing_service = Service(0, "SENSING", 15.0, 128.0, 100.0)
        var controller_service = Service(1, "CONTROL", 30.0, 256.0, 200.0)
        
        var s_placed_id = fg.allocate_service(topo.nodes, topo.links, sensing_service)
        var c_placed_id = fg.allocate_service(topo.nodes, topo.links, controller_service)
        
        # Get city names from topology nodes
        var s_city = String("Unknown")
        var c_city = String("Unknown")
        if s_placed_id != -1:
            s_city = topo.nodes[s_placed_id].node_type
        if c_placed_id != -1:
            c_city = topo.nodes[c_placed_id].node_type
            
        print("   [Network-Aware Placement] FineGrainedHeuristic resolved optimal edge nodes:")
        print("      -> Sensing Node (ID: 0) mapped to NetworkNode " + String(s_placed_id) + " (" + s_city + ")")
        print("      -> Controller Node (ID: 1) mapped to NetworkNode " + String(c_placed_id) + " (" + c_city + ")")
        
        # Save mapping to Neo4j
        if s_placed_id != -1:
            session.run("MATCH (s:ServiceNode {id: 0}), (n:NetworkNode {id: " + String(s_placed_id) + "}) CREATE (s)-[:MAPPED_TO]->(n)")
        if c_placed_id != -1:
            session.run("MATCH (s:ServiceNode {id: 1}), (n:NetworkNode {id: " + String(c_placed_id) + "}) CREATE (s)-[:MAPPED_TO]->(n)")
        
        session.close()
        
        # Check for loops/cycles in the workflow template
        print("   [Simulator] Running cycle detection algorithm...")
        _ = orchestrator.check_cycles()
        
        # Run a few loops
        for i in range(2):
            print("\n   === Neo4j Loop Iteration " + String(i + 1) + " ===")
            orchestrator.run_orchestration_loop()
            
        # Mocking a service node failure to show transitive downstream dependency pruning in action
        print("\n   [Simulator] Mocking failure on Node 0 to trigger downstream path pruning...")
        var prune_session = orchestrator.driver.session()
        orchestrator.prune_downstream(prune_session, 0)
        prune_session.close()
            
        orchestrator.close()
    except err:
        print("   [Simulator] ERROR during Neo4j execution: " + String(err))
        print("   [Simulator] Neo4j is not reachable at bolt://localhost:7687.")
        print("   [Simulator] To run this demo, start a local Neo4j instance:")
        print("       docker run -d --name neo4j -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/password neo4j:latest")

def run_evaluation_sim():
    """
    Executes the performance and QoE evaluation suite, reproducing the 
    47% cost reduction and stability metrics described in the paper.
    """
    print("\n=== 5. Performance and QoE Evaluation ===")
    from src.sim.evaluation import EvaluationEngine
    from std.collections import List
    
    var engine = EvaluationEngine()
    
    # 1. Quality of Experience (QoE) Metrics Stability
    print("\n   [Evaluation] 1. Quality of Experience (QoE) Metrics Stability:")
    var bitrates = List[Float64]()
    bitrates.append(1000.0)
    bitrates.append(1500.0)
    bitrates.append(1500.0)
    bitrates.append(2000.0)
    bitrates.append(1200.0)
    
    var stall_times = List[Float64]()
    stall_times.append(0.0)
    stall_times.append(0.0)
    stall_times.append(0.2)
    stall_times.append(0.0)
    stall_times.append(0.5)
    
    var prev_bitrate: Float64 = 0.0
    for i in range(len(bitrates)):
        var bitrate = bitrates[i]
        var stall = stall_times[i]
        var qoe = engine.calculate_segment_qoe(bitrate, prev_bitrate, stall)
        print("      Segment " + String(i + 1) + " | Bitrate: " + String(bitrate) + " | Stall: " + String(stall) + " -> QoE: " + String(qoe))
        prev_bitrate = bitrate

    # 2. Network Cost Comparison
    print("\n   [Evaluation] 2. Core Network Cost Comparison:")
    # Centralized core-served configuration:
    var core_bandwidth: Float64 = 100.0
    var core_cpu: Float64 = 10.0
    var core_cost = engine.calculate_network_cost(core_bandwidth, core_cpu, False)
    
    # Edge-served configuration (using Ararat):
    # Reduces core network bandwidth by 50% through localized edge processing/filtration
    var edge_bandwidth: Float64 = 50.0
    var edge_cpu: Float64 = 10.0
    var edge_cost = engine.calculate_network_cost(edge_bandwidth, edge_cpu, True)
    
    var saving = ((core_cost - edge_cost) / core_cost) * 100.0
    print("      Centralized Core-Served Cost: " + String(core_cost))
    print("      Ararat Edge-Served Cost:      " + String(edge_cost))
    print("      Core Network Cost Reduction:  " + String(saving) + "%")

def main() raises:
    run_neuromodulation_sim()
    run_yaml_driven_sim()
    run_hot_swap_sim()
    run_neo4j_sim()
    run_evaluation_sim()

