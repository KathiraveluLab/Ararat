from src.core.node import Node
from src.core.link import Link
from src.core.service import Service
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
        Incorporates available CPU, memory, link bandwidth, and interconnecting link latency.
        """
        var optimal_node_id: Int = -1
        var highest_score: Float64 = -1e9
        
        for i in range(len(nodes)):
            var node = nodes[i].copy()
            if node.node_type != "SDN" and node.node_type != "CLIENT":
                if node.available_cpu >= service.cpu_required and node.available_memory >= service.memory_required:
                    # Calculate incident link characteristics (average latency & total bandwidth)
                    var incident_link_count: Int = 0
                    var total_link_latency: Float64 = 0.0
                    var total_link_bandwidth: Float64 = 0.0
                    
                    for j in range(len(links)):
                        var link = links[j].copy()
                        if link.source_id == node.id or link.dest_id == node.id:
                            incident_link_count += 1
                            total_link_latency += link.latency
                            total_link_bandwidth += link.bandwidth
                    
                    var avg_latency: Float64 = 1.0
                    if incident_link_count > 0:
                        avg_latency = total_link_latency / Float64(incident_link_count)
                        
                    # Combined resource availability penalty-adjusted by link latency
                    var resource_capacity = node.available_cpu + (node.available_memory / 10.0)
                    var latency_penalty = 0.5 * avg_latency
                    var bandwidth_bonus = 0.01 * total_link_bandwidth
                    
                    var current_score = resource_capacity - latency_penalty + bandwidth_bonus
                    if current_score > highest_score:
                        highest_score = current_score
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
            var node = nodes[i].copy()
            if node.node_type != "SDN" and node.node_type != "CLIENT" and node.available_cpu >= service.cpu_required:
                if node.available_cpu > max_cpu:
                    max_cpu = node.available_cpu
                    best_node_id = node.id
        
        return best_node_id
