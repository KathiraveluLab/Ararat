from ararat.core.node import Node
from ararat.core.link import Link
from ararat.core.service import Service
from std.collections import List

struct FineGrainedHeuristic:
    """
    Implements the Fine-Grained Heuristic for ARARAT.
    Targets polynomial-time execution for edge collaboration.
    """
    def __init__(out self):
        pass

    def allocate_service(
        self, 
        nodes: List[Node], 
        links: List[Link], 
        service: Service
    ) -> Int:
        """
        Finds the optimal Edge node for a given service request.
        Minimal implementation focusing on resource availability.
        """
        var optimal_node_id: Int = -1
        var highest_resource_availability: Float64 = 0.0
        
        for i in range(len(nodes)):
            var node = nodes[i]
            if node.node_type == "EDGE":
                if node.available_cpu >= service.cpu_required and node.available_memory >= service.memory_required:
                    # Heuristic score: Combined available resources
                    var current_score = node.available_cpu + node.available_memory
                    if current_score > highest_resource_availability:
                        highest_resource_availability = current_score
                        optimal_node_id = node.id
        
        return optimal_node_id

    def calculate_serving_time(mut self, transmission_time: Float64, processing_time: Float64) -> Float64:
        """
        Serving time is the sum of transmission and processing time.
        """
        return transmission_time + processing_time

struct CoarseGrainedHeuristic:
    """
    Implements the Coarse-Grained Heuristic for ARARAT.
    Provides a greedy, sub-optimal baseline for service placement.
    """
    def __init__(out self):
        pass

    def allocate_service(
        self, 
        nodes: List[Node], 
        service: Service
    ) -> Int:
        """
        Selects the node with the absolute highest available CPU capacity.
        Ignores network distance and link costs.
        """
        var best_node_id: Int = -1
        var max_cpu: Float64 = -1.0
        
        for i in range(len(nodes)):
            var node = nodes[i]
            if node.node_type == "EDGE" and node.available_cpu >= service.cpu_required:
                if node.available_cpu > max_cpu:
                    max_cpu = node.available_cpu
                    best_node_id = node.id
        
        return best_node_id
