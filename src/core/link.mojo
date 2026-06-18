struct Link(Copyable, Movable):
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

    def __copyinit__(out self, other: Self):
        self.source_id = other.source_id
        self.dest_id = other.dest_id
        self.bandwidth = other.bandwidth
        self.latency = other.latency
        self.available_bandwidth = other.available_bandwidth

    def __moveinit__(out self, owned other: Self):
        self.source_id = other.source_id
        self.dest_id = other.dest_id
        self.bandwidth = other.bandwidth
        self.latency = other.latency
        self.available_bandwidth = other.available_bandwidth

    def copy(self) -> Self:
        var res = Link(self.source_id, self.dest_id, self.bandwidth, self.latency)
        res.available_bandwidth = self.available_bandwidth
        return res^

    def display(mut self):
        print("Link:", self.source_id, "->", self.dest_id, "BW Capacity:", self.bandwidth, "Latency:", self.latency)
