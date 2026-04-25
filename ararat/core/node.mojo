from std.collections import Optional

struct Node:
    var id: Int
    var node_type: String # "SDN", "EDGE", "CLIENT"
    var cpu_capacity: Float64
    var memory_capacity: Float64
    var available_cpu: Float64
    var available_memory: Float64
    
    def __init__(out self, id: Int, node_type: String, cpu: Float64, memory: Float64):
        self.id = id
        self.node_type = node_type
        self.cpu_capacity = cpu
        self.memory_capacity = memory
        self.available_cpu = cpu
        self.available_memory = memory

    def display(mut self):
        print("Node ID:", self.id, "Type:", self.node_type, "CPU Capacity:", self.cpu_capacity, "Available CPU:", self.available_cpu)
