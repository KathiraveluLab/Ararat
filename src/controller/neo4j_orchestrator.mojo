from std.python import Python, PythonObject
from src.infra.launcher import ServiceLauncher

struct Neo4jOrchestrator:
    """
    Stateless, database-driven orchestrator for Ararat.
    Coordinates execution of Directed Hypergraph (DHG) workflows directly 
    using Neo4j as the shared state machine and control plane.
    """
    var driver: PythonObject
    var launcher: ServiceLauncher

    def __init__(out self, uri: String, auth_user: String, auth_pass: String) raises:
        """
        Initializes the connection to the Neo4j instance.
        """
        var neo4j = Python.import_module("neo4j")
        var builtins = Python.import_module("builtins")
        var auth_list = builtins.list()
        auth_list.append(auth_user)
        auth_list.append(auth_pass)
        var auth = builtins.tuple(auth_list)
        self.driver = neo4j.GraphDatabase.driver(uri, auth=auth)
        self.launcher = ServiceLauncher()
        print("[Neo4j Orchestrator] Connected to Neo4j database at: " + uri)

    def close(self) raises:
        """
        Closes the active database connection.
        """
        self.driver.close()
        print("[Neo4j Orchestrator] Database connection closed.")

    def run_orchestration_loop(mut self) raises:
        """
        Executes a single pass of the stateless orchestration query:
        1. Find a pending ServiceNode whose incoming dependencies are satisfied.
        2. Set its status to RUNNING.
        3. Execute the service implementation using the ServiceLauncher.
        4. Update status and propagate outbound hyperedge states.
        """
        var session = self.driver.session()
        
        # Cypher query to retrieve and lock the next ready node atomically
        var fetch_query = (
            "MATCH (n:ServiceNode {status: 'PENDING'}) "
            "WHERE NOT (n)<-[:INFLOW]-(:Hyperedge {status: 'IDLE'}) "
            "WITH n LIMIT 1 "
            "SET n.status = 'RUNNING' "
            "RETURN n.id AS id, n.name AS name, n.platform AS platform, n.image AS image"
        )
        
        var result = session.run(fetch_query)
        if result.has_next():
            var record = result.next()
            var node_id = atol(String(record["id"]))
            var name = String(record["name"])
            var platform = String(record["platform"])
            var image = String(record["image"])
            
            print("\n   [Control Plane] Claimed Node " + String(node_id) + " :: " + name)
            print("   [Control Plane] Executing on platform: " + platform + " with image: " + image)
            
            try:
                self.launcher.launch_container(platform, image, "")
                self._mark_node_completed(session, node_id)
            except:
                print("   [Control Plane] ERROR: Execution failed for Node " + String(node_id))
                self._mark_node_failed(session, node_id)
        else:
            print("   [Control Plane] No pending ready nodes found. Workflow completed or blocked.")
            
        session.close()

    def _mark_node_completed(self, session: PythonObject, node_id: Int) raises:
        """
        Marks a node as COMPLETED and sets its outbound hyperedges to ACTIVE.
        """
        var complete_query = (
            "MATCH (n:ServiceNode {id: $node_id}) "
            "SET n.status = 'COMPLETED' "
            "WITH n "
            "MATCH (n)-[:OUTFLOW]->(edge:Hyperedge) "
            "SET edge.status = 'ACTIVE' "
            "RETURN edge.label AS label"
        )
        var parameters = Python.dict()
        parameters["node_id"] = node_id
        
        var result = session.run(complete_query, parameters)
        print("   [Control Plane] Node " + String(node_id) + " marked COMPLETED.")
        while result.has_next():
            var record = result.next()
            print("   [Sync Signal] Activated Outbound Hyperedge: " + String(record["label"]))

    def _mark_node_failed(self, session: PythonObject, node_id: Int) raises:
        """
        Marks a node as FAILED.
        """
        var fail_query = (
            "MATCH (n:ServiceNode {id: $node_id}) "
            "SET n.status = 'FAILED' "
            "RETURN n.id"
        )
        var parameters = Python.dict()
        parameters["node_id"] = node_id
        session.run(fail_query, parameters)
        print("   [Control Plane] Node " + String(node_id) + " marked FAILED.")
