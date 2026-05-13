struct Link:
    var source_id: Int
    var dest_id: Int
    var bandwidth: Float64
    var latency: Float64
    var available_bandwidth: Float64
    
    def __init__(out self, source_id: Int, dest_id: Int, bandwidth: Float64, latency: Float64):
        self.source_id = source_id
        self.dest_id = dest_id
        self.bandwidth = bandwidth
        self.latency = latency
        self.available_bandwidth = bandwidth

    def display(mut self):
        print("Link:", self.source_id, "->", self.dest_id, "BW Capacity:", self.bandwidth, "Latency:", self.latency)
