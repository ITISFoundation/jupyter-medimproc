Based on my analysis of the cookiecutter-osparc-service repository, here are the key elements required for creating a new osparc computational service.

## Key Elements of an Osparc Computational Service

Creating a service for the Osparc platform requires adherence to a specific contract regarding metadata, container structure, and runtime behavior. Here are the critical components:

### 1. Service Definition Information (metadata.yml)
This is the single source of truth for your service. It defines how the platform interacts with your code.
*   **Identity**: `name`, `key` (namespace like `simcore/services/comp/...`), `version`, and `type`.
*   **Interface Contract**: Defines **Inputs** and **Outputs**.
    *   `fileToKeyMap`: Crucial mapping that tells the platform which physical file corresponds to which input/output key.
    *   `type`: Data types (e.g., `data:*/*`, `integer`, `string`).
    *   `defaultValue`: Useful for optional parameters.

### 2. The User Identity (`scu`)
Osparc services are designed to run as a non-root user for security.
*   **UID 8004**: The Dockerfile usually sets up a specific user named `scu` with UID `8004`.
*   **Permissions**: Your application logic runs as this user, so it must have appropriate permissions for the working directory.

### 3. The "Entrypoint Magic" (entrypoint.sh)
This is perhaps the most critical operational component for data persistence.
*   **Volume Mounting**: The platform mounts input and output folders creates from the host system. The permissions of these mounted folders might not match the internal `scu` user.
*   **Runtime Permission Fix**: The entrypoint.sh script runs as `root` (initially) to inspect the mounted volumes. It dynamically changes the `scu` user's UID/GID to match the owner of the mounted input/output folders. This ensures your service can read inputs and write outputs without "Permission Denied" errors.
*   **Handoff**: After fixing permissions, it switches user (`su`) to `scu` to execute the actual application logic.

### 4. Input/Output Data Handling
*   **Environment Variables**: The service receives locations via `INPUT_FOLDER` and `OUTPUT_FOLDER` environment variables.
*   **Read inputs**: Your code should expect input files in `${INPUT_FOLDER}` (filenames roughly correspond to your metadata.yml definition).
*   **Write outputs**: Your code must write results to `${OUTPUT_FOLDER}`.

### 5. Execution Wrapper (execute.sh)
This script serves as the bridge between the container setup and your actual application code (e.g., Python script).
*   It is typically the command run by the `scu` user after the entrypoint handoff.
*   It invokes your main executable (e.g., `python3 src/main.py`), often passing the input/output folder paths as arguments.

### 6. File Structure Standard
*   **`src/`**: Contains your source code.
*   **`docker/`**: Contains Dockerfiles (often multi-stage: base, build, production).
*   **`service.cli/`**: Contains the execution scripts.
*   **Makefile**: Standardizes build and test commands.
    *   **`make compose-spec`**: A key command that uses a tool called `ooil` to auto-generate the docker-compose.yml based on your metadata.yml. This ensures your container configuration always matches your service definition.

### Summary Checklist for a New Service
1.  Define usage in **metadata.yml**.
2.  Ensure Dockerfile creates user **`scu` (8004)**.
3.  Include the standard **entrypoint.sh** to handle volume permissions.
4.  Write an **execute.sh** wrapper to call your code.
5.  Read inputs from **`$INPUT_FOLDER`** and write to **`$OUTPUT_FOLDER`**.