from src.sim.closed_loop_sim import run_neuromodulation_sim, run_yaml_driven_sim, run_hot_swap_sim, run_neo4j_sim

def main() raises:
    """
    Entry point for the Ararat Framework simulation.
    Orchestrates a Software-Defined Workflow (SDW) across a 
    Directed Hypergraph (DHG) modeling a closed-loop neuromodulation system.
    """
    print("\n=== 1. Programmatic Simulation (API) ===")
    run_neuromodulation_sim()
    print("\n=== 2. YAML-Driven Simulation (neuromodulation.yaml) ===")
    run_yaml_driven_sim()
    print("\n=== 3. Hot-Swap Simulation (dynamic_update.yaml) ===")
    run_hot_swap_sim()
    print("\n=== 4. Neo4j-Native Simulation ===")
    run_neo4j_sim()

