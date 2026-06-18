struct Service(Copyable, Movable):
    var id: Int
    var service_type: String # "TRANSCODING", "CACHING", "STREAMING"
    var cpu_required: Float64
    var memory_required: Float64
    var bandwidth_required: Float64
    
    def __init__(out self, id: Int, service_type: String, cpu_req: Float64, mem_req: Float64, bw_req: Float64):
        self.id = id
        self.service_type = service_type
        self.cpu_required = cpu_req
        self.memory_required = mem_req
        self.bandwidth_required = bw_req

    def __copyinit__(out self, other: Self):
        self.id = other.id
        self.service_type = other.service_type
        self.cpu_required = other.cpu_required
        self.memory_required = other.memory_required
        self.bandwidth_required = other.bandwidth_required

    def __moveinit__(out self, owned other: Self):
        self.id = other.id
        self.service_type = other.service_type^
        self.cpu_required = other.cpu_required
        self.memory_required = other.memory_required
        self.bandwidth_required = other.bandwidth_required

    def copy(self) -> Self:
        return Service(self.id, self.service_type, self.cpu_required, self.memory_required, self.bandwidth_required)

    def display(mut self):
        print("Service ID:", self.id, "Type:", self.service_type, "CPU Req:", self.cpu_required, "BW Req:", self.bandwidth_required)
