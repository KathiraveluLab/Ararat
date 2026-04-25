from std.python import Python

struct ServiceLauncher:
    """
    Infrastructure Layer: Handles the execution of external service instances.
    Enables Ararat to orchestrate Docker, Singularity, and Local processes.
    As specified in NEXUS Section I.E: 'supports services running across multiple execution environments'.
    """
    
    def __init__(out self):
        pass

    def launch_container(mut self, platform: String, image: String, params: String) raises:
        """
        Launches a containerized service using the specified platform (docker/singularity).
        """
        var subprocess = Python.import_module("subprocess")
        print("   [Launcher] Initializing " + platform + " instance: " + image)
        
        var cmd: String = ""
        if platform == "docker":
            cmd = "docker run --rm " + image + " " + params
        elif platform == "singularity":
            cmd = "singularity run " + image + " " + params
        else:
            cmd = "python3 " + image + " " + params # Fallback to local python executor
            
        # Execute synchronously for blocking hyperedges, or asynchronously for non-blocking
        # In this skeleton, we show the synchronous call logic
        try:
            subprocess.run(cmd, shell=True, check=True)
            print("   [Launcher] Service execution completed successfully.")
        except:
            print("   [Launcher] ERROR: Service execution failed for " + image)

    def exec_shell_script(mut self, script_path: String) raises:
        """
        Executes a standalone research script (Algorithm 1: execScripts).
        """
        var subprocess = Python.import_module("subprocess")
        print("   [Launcher] Executing Script: " + script_path)
        subprocess.run(script_path, shell=True, check=True)
