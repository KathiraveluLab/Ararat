# Ararat Tutorial: Running Real Workflows

This tutorial walks you through running the two workflow definitions
(`neuromodulation.yaml` and `dynamic_update.yaml`) against the actual prototype
images that back them.

---

## Prerequisites

Install dependencies and activate the pixi environment:

```bash
pixi install
```

Build the Docker image for the Plant Model node:

```bash
docker build -t kathiravelulab/neuromod-pm:latest scripts/neuromod-pm/
```

Verify both prototype implementations exist:

```bash
ls scripts/
# bayesian_optimizer.py       (local Python node)
# neuromod-pm/                (Docker node)
#   Dockerfile
#   plant_model.sh
```

---

## Workflow Overview

| YAML file | Purpose |
|---|---|
| `workflows/neuromodulation.yaml` | Initial closed-loop workflow with two synchronous edges |
| `workflows/dynamic_update.yaml`  | Hot-swap update — converts the recording edge to asynchronous |

### Node Definitions in `neuromodulation.yaml`

```yaml
nodes:
  - id: 0
    name: Plant Model (PM)
    platform: docker
    image: kathiravelulab/neuromod-pm:latest   # Built from scripts/neuromod-pm/

  - id: 1
    name: Bayesian Optimizer (CTL)
    platform: local
    image: scripts/bayesian_optimizer.py        # scripts/bayesian_optimizer.py
```

- **`platform: docker`** — the Ararat Orchestrator will call `docker run --rm <image>` when executing this node.
- **`platform: local`** — the Ararat Orchestrator will call `python3 <image>` for this node.

---

## Simulation 1 — Programmatic API (no YAML)

This is the baseline, defined directly in Mojo:

```bash
pixi run mojo main.mojo
```

The orchestrator creates Plant Model (PM) and Bayesian Optimizer (CTL) nodes
in-process, then runs 20 synchronous iterations of the closed-loop:

```
--- [Global Iteration 1] ---
   [Control Event] Node 0 :: TRIGGER_EXECUTION
   [Service] Plant Model (PM) processing iteration data...
   [Sync Signal] Blocking until ACK from destinations of NEURAL_RECORDING
Hyperedge [NEURAL_RECORDING] (Synchronous): 0 -> {1 }
   [Control Event] Node 1 :: DATA_AVAILABLE
   [Control Event] Node 1 :: TRIGGER_EXECUTION
   [Service] Bayesian Optimizer (CTL) processing iteration data...
   [Sync Signal] Blocking until ACK from destinations of STIMULATION_PARAMS
Hyperedge [STIMULATION_PARAMS] (Synchronous): 1 -> {0 }
   [Control Event] Node 0 :: DATA_AVAILABLE
```

---

## Simulation 2 — YAML-Driven Workflow (`neuromodulation.yaml`)

The `WorkflowParser` reads `neuromodulation.yaml`, constructs the nodes and
hyperedges from it, and passes them to the Ararat Orchestrator:

```bash
pixi run mojo main.mojo
# Look for the section: "=== 2. YAML-Driven Simulation ==="
```

You can also invoke this sim function directly:

```mojo
from src.sim.closed_loop_sim import run_yaml_driven_sim

def main() raises:
    run_yaml_driven_sim()
```

**What the parser prints during loading:**

```
[Parser] Loading nodes from: workflows/neuromodulation.yaml
   -> Node 0: Plant Model (PM) [docker] kathiravelulab/neuromod-pm:latest
   -> Node 1: Bayesian Optimizer (CTL) [local] scripts/bayesian_optimizer.py
[Parser] Loading edges from: workflows/neuromodulation.yaml
   -> Hyperedge [NEURAL_RECORDING]: 0 -> destinations
   -> Hyperedge [STIMULATION_PARAMS]: 1 -> destinations
```

The `platform` and `image` fields are read and logged — they identify **which
implementation backs each node**.

---

## Simulation 3 — Dynamic Hot-Swap (`dynamic_update.yaml`)

This demonstrates live topology reconfiguration **without restarting any nodes**.

The orchestrator:
1. Loads and runs one pass of `neuromodulation.yaml` (both edges synchronous).
2. Calls `load_edges_from_yaml("workflows/dynamic_update.yaml")` to get new edges.
3. Calls `update_topology()` — the Northbound API hot-swap operation.
4. Runs another pass with the **updated** topology.

```bash
pixi run mojo main.mojo
# Look for the section: "=== 3. Hot-Swap Simulation ==="
```

**Key output showing the hot-swap event:**

```
>> Phase 1: Standard Synchronous Control Flow
   [Sync Signal] Blocking until ACK from destinations of NEURAL_RECORDING
   [Sync Signal] Blocking until ACK from destinations of STIMULATION_PARAMS

[Control Plane] !!! HOT-SWAPPING WORKFLOW TOPOLOGY !!!
   -> New Path Active: THIN_EDGE_RECORDING       # was NEURAL_RECORDING (sync)
   -> New Path Active: STIMULATION_FEEDBACK       # was STIMULATION_PARAMS (sync)

>> Phase 2: Post-Update Control Flow (Asynchronous Signaling)
   [Async Signal] Fire-and-forget update via Thin Edge THIN_EDGE_RECORDING
   [Sync Signal] Blocking until ACK from destinations of STIMULATION_FEEDBACK
```

Notice that `THIN_EDGE_RECORDING` is now **Asynchronous** (fire-and-forget),
while `STIMULATION_FEEDBACK` remains synchronous — exactly as defined in
`dynamic_update.yaml`.

### What changed between the two YAMLs

| Field | `neuromodulation.yaml` | `dynamic_update.yaml` |
|---|---|---|
| Edge 1 label | `NEURAL_RECORDING` | `THIN_EDGE_RECORDING` |
| Edge 1 `is_blocking` | `1` (sync) | `0` (async, thin edge) |
| Edge 2 label | `STIMULATION_PARAMS` | `STIMULATION_FEEDBACK` |
| Edge 2 `is_blocking` | `1` (sync) | `1` (sync, unchanged) |

---

## Running All Three Simulations at Once

```bash
pixi run mojo main.mojo
```

`main.mojo` calls all three in sequence:

```mojo
from src.sim.closed_loop_sim import run_neuromodulation_sim, run_yaml_driven_sim, run_hot_swap_sim

def main() raises:
    print("\n=== 1. Programmatic Simulation (API) ===")
    run_neuromodulation_sim()
    print("\n=== 2. YAML-Driven Simulation (neuromodulation.yaml) ===")
    run_yaml_driven_sim()
    print("\n=== 3. Hot-Swap Simulation (dynamic_update.yaml) ===")
    run_hot_swap_sim()
```

---

## Adding Your Own Workflow

1. Create a new YAML file in `workflows/`:

```yaml
workflow_name: My Custom Workflow
nodes:
  - id: 0
    name: Sensor Node
    platform: local
    image: scripts/my_sensor.py
  - id: 1
    name: Aggregator
    platform: docker
    image: myregistry/aggregator:latest
edges:
  - id: 1
    label: SENSOR_DATA
    source: 0
    destinations:
      - 1
    is_blocking: 0    # async (thin edge)
```

2. Load it via the API:

```mojo
from src.infra.parser import WorkflowParser
from src.controller.sdn import AraratOrchestrator

def my_sim() raises:
    var parser = WorkflowParser()
    var orchestrator = AraratOrchestrator()

    var nodes = parser.load_nodes_from_yaml("workflows/my_workflow.yaml")
    var edges = parser.load_edges_from_yaml("workflows/my_workflow.yaml")

    orchestrator.initialize_workflow(nodes, edges)
    orchestrator.run_simulation(10)
```

3. To hot-swap during a run, call `load_edges_from_yaml` on a second YAML and
   pass the result to `orchestrator.update_topology(new_edges)`.
