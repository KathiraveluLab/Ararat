@value
struct Service:
    var id: Int
    var service_type: String # "TRANSCODING", "CACHING", "STREAMING"
    var cpu_required: Float64
    var memory_required: Float64
    var bandwidth_required: Float64
    
    fn __init__(inout self, id: Int, service_type: String, cpu_req: Float64, mem_req: Float64, bw_req: Float64):
        self.id = id
        self.service_type = service_type
        self.cpu_required = cpu_req
        self.memory_required = mem_req
        self.bandwidth_required = bw_req

    fn display(self):
        print("Service ID:", self.id, "Type:", self.service_type, "CPU Req:", self.cpu_required, "BW Req:", self.bandwidth_required)
