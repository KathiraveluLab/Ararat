from collections import List

struct Hyperedge:
    """
    Represents a Directed Hyperedge in a Directed Hypergraph (DHG).
    Defined in Ararat.pdf as {source, [destinations]}.
    """
    var id: Int
    var label: String
    var source_id: Int
    var destination_ids: List[Int]
    var is_blocking: Bool # Synchronous (True) or Asynchronous (False)
    
    fn __init__(
        inout self, 
        id: Int, 
        label: String, 
        source_id: Int, 
        destination_ids: List[Int], 
        is_blocking: Bool = True
    ):
        self.id = id
        self.label = label
        self.source_id = source_id
        self.destination_ids = destination_ids
        self.is_blocking = is_blocking
        
    fn display(self):
        var dest_str: String = ""
        for i in range(len(self.destination_ids)):
            dest_str += str(self.destination_ids[i]) + " "
        
        var sync_type = String("Synchronous") if self.is_blocking else String("Asynchronous")
        print("Hyperedge [" + self.label + "] (" + sync_type + "): " + str(self.source_id) + " -> {" + dest_str + "}")
