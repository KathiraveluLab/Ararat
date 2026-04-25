from std.collections import List

struct Hyperedge(Copyable, Movable):
    var id: Int
    var label: String
    var source_id: Int
    var destination_ids: List[Int]
    var is_blocking: Bool
    
    def __init__(out self, id: Int, label: String, source_id: Int, destination_ids: List[Int], is_blocking: Bool = True):
        self.id = id
        self.label = label
        self.source_id = source_id
        self.destination_ids = destination_ids.copy()
        self.is_blocking = is_blocking
        
    def __copyinit__(out self, other: Self):
        self.id = other.id
        self.label = other.label
        self.source_id = other.source_id
        self.destination_ids = other.destination_ids.copy()
        self.is_blocking = other.is_blocking

    def __moveinit__(out self, owned other: Self):
        self.id = other.id
        self.label = other.label
        self.source_id = other.source_id
        self.destination_ids = other.destination_ids^
        self.is_blocking = other.is_blocking

    def copy(self) -> Self:
        var res = Hyperedge(self.id, self.label, self.source_id, self.destination_ids.copy(), self.is_blocking)
        return res^

    def display(mut self):
        var dest_str: String = ""
        for i in range(len(self.destination_ids)):
            dest_str += String(self.destination_ids[i]) + " "
        var sync_type = String("Synchronous") if self.is_blocking else String("Asynchronous")
        print("Hyperedge [" + self.label + "] (" + sync_type + "): " + String(self.source_id) + " -> {" + dest_str + "}")
