from ..core.node import Node
from ..core.link import Link
from collections import List

struct ETT2018Topology:
    """
    Implementation of the European Trunk Topology (ETT) 2018 benchmark.
    Consists of 12 Nodes and 18 bi-directional Links.
    """
    var nodes: List[Node]
    var links: List[Link]
    
    fn __init__(inout self):
        self.nodes = List[Node]()
        self.links = List[Link]()
        self.initialize_nodes()
        self.initialize_links()
        
    fn initialize_nodes(inout self):
        # 12 major European cities (Node IDs: 0 to 11)
        let cities = List[String](
            "London", "Paris", "Amsterdam", "Berlin", "Vienna", 
            "Warsaw", "Prague", "Zurich", "Milan", "Madrid", 
            "Rome", "Frankfurt"
        )
        for i in range(len(cities)):
            # Initializing with standard edge resource capacities
            self.nodes.append(Node(i, cities[i], 100.0, 1024.0)) # 100 CPU units, 1GB RAM
            
    fn initialize_links(inout self):
        # Default research parameters for ETT
        let bw = 10000.0 # 10,000 Mbps (10 Gbps) bandwidth
        let lat = 10.0   # 10.0 ms average latency
        
        # Defining 18 primary links (IDs correspond to cities list)
        self.add_link(0, 1, bw, lat)  # London-Paris
        self.add_link(1, 2, bw, lat)  # Paris-Amsterdam
        self.add_link(1, 9, bw, lat)  # Paris-Madrid
        self.add_link(1, 7, bw, lat)  # Paris-Zurich
        self.add_link(2, 3, bw, lat)  # Amsterdam-Berlin
        self.add_link(3, 5, bw, lat)  # Berlin-Warsaw
        self.add_link(3, 6, bw, lat)  # Berlin-Prague
        self.add_link(3, 11, bw, lat) # Berlin-Frankfurt
        self.add_link(11, 7, bw, lat) # Frankfurt-Zurich
        self.add_link(11, 6, bw, lat) # Frankfurt-Prague
        self.add_link(6, 4, bw, lat)  # Prague-Vienna
        self.add_link(6, 5, bw, lat)  # Prague-Warsaw
        self.add_link(4, 5, bw, lat)  # Vienna-Warsaw
        self.add_link(4, 8, bw, lat)  # Vienna-Milan
        self.add_link(7, 8, bw, lat)  # Zurich-Milan
        self.add_link(8, 10, bw, lat) # Milan-Rome
        self.add_link(9, 0, bw, lat)  # Madrid-London
        self.add_link(10, 11, bw, lat)# Rome-Frankfurt

    fn add_link(inout self, src: Int, dest: Int, bw: Float64, lat: Float64):
        # Each 'link' in the topology is bi-directional
        self.links.append(Link(src, dest, bw, lat))
        self.links.append(Link(dest, src, bw, lat))

    fn display_status(self):
        print("ETT 2018 Topology Summary:")
        print(" - Nodes Loaded: ", len(self.nodes))
        print(" - Active Bi-directional Links: ", len(self.links))
