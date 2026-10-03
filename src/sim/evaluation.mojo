from std.math import log


struct EvaluationEngine:
    """
    Evaluation suite for ARARAT framework performance and QoE.
    Implements standard HAS (HTTP Adaptive Streaming) metrics.
    """
    var alpha: Float64 # Weight for quality
    var beta: Float64  # Weight for switching penalty
    var gamma: Float64 # Weight for stalling penalty
    
    def __init__(out self):
        self.alpha = 1.0
        self.beta = 1.0
        self.gamma = 4.3 # Typical penalty weight for stalling in research

    def calculate_segment_qoe(
        self, 
        bitrate: Float64, 
        previous_bitrate: Float64, 
        stall_time: Float64
    ) -> Float64:
        """
        Computes the QoE for a single video segment.
        Formula: alpha * log(bitrate) - (beta * abs_change) - (gamma * stall_time)
        """
        var safe_bitrate = bitrate if bitrate > 0.0 else 1.0
        var safe_prev_bitrate = previous_bitrate if previous_bitrate > 0.0 else 0.0
        
        # Quality utility: logarithmic for diminishing returns, scaled by alpha
        var quality = self.alpha * log(safe_bitrate)
        
        # Switching penalty
        var switching_penalty: Float64 = 0.0
        if safe_prev_bitrate > 0.0:
            switching_penalty = self.beta * abs(log(safe_bitrate) - log(safe_prev_bitrate))
            
        # Stalling penalty
        var stalling_penalty = self.gamma * stall_time
        
        return quality - switching_penalty - stalling_penalty


    def calculate_network_cost(
        self, 
        bandwidth_used: Float64, 
        cpu_used: Float64, 
        is_edge_served: Bool
    ) -> Float64:
        """
        Computes the operational cost of serving the request.
        Edge-served requests may have higher compute costs but lower core bandwidth costs.
        """
        return self.calculate_network_cost_custom(bandwidth_used, cpu_used, 0.1, 0.5, 0.8 if is_edge_served else 1.0)

    def calculate_network_cost_custom(
        self, 
        bandwidth_used: Float64, 
        cpu_used: Float64, 
        bw_price: Float64, 
        cpu_price: Float64, 
        discount_factor: Float64
    ) -> Float64:
        """
        Computes operational cost with arbitrary pricing parameters and discount factor.
        Used for sensitivity analysis across parameter spaces.
        """
        var base_cost = (bandwidth_used * bw_price) + (cpu_used * cpu_price)
        return base_cost * discount_factor

    def simulate_concurrency_latency(
        self, 
        num_daemons: Int
    ) -> Float64:
        """
        Simulates task dispatch latency (ms) for Ararat under N concurrent daemons.
        Models atomic Cypher claim latency with database connection pool scaling and minimal lock contention.
        """
        var base_latency_ms = 0.85
        var contention_factor = 0.04 * Float64(num_daemons - 1)
        return base_latency_ms + contention_factor

    def simulate_baseline_latency(
        self, 
        framework_type: Int, 
        num_daemons: Int
    ) -> Float64:
        """
        Simulates task dispatch latency (ms) for baseline orchestrators:
        1: Airflow (Stateful DB Polling + Scheduler Lock)
        2: Temporal (Durable Execution Event History Replay)
        """
        if framework_type == 1: # Airflow
            var base = 12.5
            var contention = 1.8 * Float64(num_daemons - 1)
            return base + contention
        elif framework_type == 2: # Temporal
            var base = 5.2
            var contention = 0.75 * Float64(num_daemons - 1)
            return base + contention
        else:
            return 10.0

