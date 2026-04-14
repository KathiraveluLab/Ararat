from ..core.node import Node
from ..core.link import Link
from ..core.service import Service
from collections import List

struct FineGrainedHeuristic:
    """
    Implements the Fine-Grained Heuristic for ARARAT.
    Targets polynomial-time execution for edge collaboration.
    """
    fn __init__(inout self):
        pass

    fn allocate_service(
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
            let node = nodes[i]
            if node.node_type == "EDGE":
                if node.available_cpu >= service.cpu_required and node.available_memory >= service.memory_required:
                    # Heuristic score: Combined available resources
                    let current_score = node.available_cpu + node.available_memory
                    if current_score > highest_resource_availability:
                        highest_resource_availability = current_score
                        optimal_node_id = node.id
        
        return optimal_node_id

    fn calculate_serving_time(self, transmission_time: Float64, processing_time: Float64) -> Float64:
        """
        Serving time is the sum of transmission and processing time.
        """
        return transmission_time + processing_time
