from std.collections import Optional

struct Node(Copyable, Movable):
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

    def __copyinit__(out self, other: Self):
        self.id = other.id
        self.node_type = other.node_type
        self.cpu_capacity = other.cpu_capacity
        self.memory_capacity = other.memory_capacity
        self.available_cpu = other.available_cpu
        self.available_memory = other.available_memory

    def __moveinit__(out self, owned other: Self):
        self.id = other.id
        self.node_type = other.node_type^
        self.cpu_capacity = other.cpu_capacity
        self.memory_capacity = other.memory_capacity
        self.available_cpu = other.available_cpu
        self.available_memory = other.available_memory

    def copy(self) -> Self:
        var res = Node(self.id, self.node_type, self.cpu_capacity, self.memory_capacity)
        res.available_cpu = self.available_cpu
        res.available_memory = self.available_memory
        return res^

    def display(mut self):
        print("Node ID:", self.id, "Type:", self.node_type, "CPU Capacity:", self.cpu_capacity, "Available CPU:", self.available_cpu)
