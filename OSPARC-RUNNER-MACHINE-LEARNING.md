# Analysis of osparc-python-runner-machine-learning

This report provides a detailed analysis of the osparc-python-runner-machine-learning repository. This repository demonstrates an advanced pattern for managing multiple related Osparc services within a single codebase, leveraging inheritance and automation to maintain consistency and reduce duplication.

## 1. Architecture Overview

The repository is structured as a "monorepo" that generates two distinct services:
1.  **PyTorch Runner** (`osparc-python-runner-pytorch`)
2.  **TensorFlow Runner** (`osparc-python-runner-tensorflow`)

These services share a significant amount of common infrastructure but target different Machine Learning execution environments.

### The "Base + Differentiation" Pattern

The repository uses a multi-stage Docker build strategy simulated via dependent images to separate the common execution logic from the specific library dependencies.

#### A. The Common Layer (`common/`)
*   **Purpose**: Defines the runtime environment, user permissions, and the core "runner" logic that is framework-agnostic.
*   **Dockerfile**:
    *   Base: `nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04` (Shared GPU-enabled OS).
    *   Setup: Creates the standard `scu` user (UID 8004).
    *   Tools: Installs global Python tools like `uv` (a fast Python package installer) and `pipreqs`.
    *   Entrypoint: Copies the standard entrypoint.sh for permissions management.
    *   Logic: Copies main.py (the generic runner script).
*   **Key Insight**: This image contains *no* heavy ML libraries, keeping it light and reusable.

#### B. The Service Layer (`osparc-python-runner-*/`)
*   **Purpose**: To provide the specific environment (PyTorch vs. TensorFlow) required by the user's code.
*   **Dockerfile**:
    *   **Inheritance**: `FROM simcore/services/comp/common:0.0.0`. It starts exactly where the common image left off.
    *   **Customization**: copies the service-specific `requirements.txt` and installs them using `uv pip install`.
    *   **Structure**: Moves the main.py into a service-specific directory (`osparc_python_runner_pytorch/` etc.) to organize the final container filesystem.

## 2. The "Runner" Logic (main.py)

Unlike typical Osparc services that perform a specific calculation (e.g., "blur an image"), these services are **Runners**. Their purpose is to blindly execute *other* Python code provided as input.

*   **Dynamic Entrypoint**: The main.py script scans the input directory for a main.py or a single Python file to execute.
*   **Dynamic Dependencies**: It looks for a `requirements.txt` in the input data and installs them on the fly (or checks them against pre-installed packages) before running the code.
*   **Execution**: It runs the identified user script ensuring environmental variables (`INPUT_FOLDER`, `OUTPUT_FOLDER`) are passed correctly.

## 3. Dual Service Generation Mechanism

The repository manages two services simultaneously through a combination of directory structure and file generation automation.

### Directory Structure & Metadata
Only the metadata differs significantly between the two services. The repository keeps them separate in the explicit .osparc folder structure:
*   metadata.yml
*   metadata.yml

This allows each service to have:
*   Unique **ids** (`simcore/services/comp/osparc-python-runner-pytorch`)
*   Independent **versions** (managed via `.bumpversion-*.cfg`)
*   Specific **input/output** definitions (though in this case, they are likely identical).

### Automation via Makefile
The Makefile is the brain of the operation:
1.  **Version Control**: Separate targets (`version-pytorch-*`, `version-tensorflow-*`) exist to bump versions independently using distinct config files.
2.  **Code Generation (`ooil`)**:
    *   The command `make create-run-script` iterates over both services.
    *   It calls a tool named `ooil run-creator` for *each* service.
    *   **Input**: The specific metadata.yml.
    *   **Output**: The `service.cli/run` script.
    *   **Benefit**: This ensures that the run script (which helps Osparc run the container) is always perfectly synced with the metadata version and docker image definitions.
3.  **Composition**: `make compose-spec` generates a single docker-compose.yml (likely distinct from the local one) that defines all build targets for the CI/CD system.

## 4. Key Takeaways for New Service Creation

If you plan to create a sophisticated Osparc service:

1.  **Don't Duplicate**: If you have "flavors" of a service (CPU vs GPU, generic vs specialized), use a **Common Base Image** pattern.
2.  **Automate Boilerplate**: Use the `ooil` tool (available in the `itisfoundation/ci-service-integration-library` docker image) to generate your docker-compose.yml and `run` scripts from your metadata.yml. Do not write them manually if you can avoid it.
3.  **Separate Metadata**: Keep metadata.yml as the source of truth. The repository directory structure should reflect the logical services, not just the code structure.
4.  **Generic Runners**: If your goal is to let users run *their* code on Osparc, investigate the main.py pattern: **Detect Script -> Install Requirements -> Execute**.


===========================

The following report combines the analysis of the standard cookiecutter-osparc-service and the advanced osparc-python-runner-machine-learning repository to provide a comprehensive guide on architecture and best practices for Osparc computational services.

# Osparc Computational Service Architecture Report

## 1. Core Anatomy of a Service
At its fundamental level, an Osparc computational service is a Docker container designed to execute a non-interactive task. It adheres to a strict contract of inputs, outputs, and permissions.

### The Metadata Contract (metadata.yml)
The metadata.yml file is the single source of truth. It defines the service's identity and interface.
*   **Identity**: Defines the Docker image name (`simcore/services/comp/...`) and version.
*   **I/O Mapping**: The `fileToKeyMap` property is crucial. It translates abstract Osparc inputs (e.g., "Input Image") into concrete file paths inside the container.
*   **Types**: Strongly typed inputs (e.g., `data:*/*`, `integer`) ensure the platform only passes valid data to the service.

### The Runtime Environment
To ensure security and proper data handling, services must follow these rules:
*   **The User**: The application logic runs as a non-root user, typically named `scu` with UID `8004`.
*   **The Environment**: The platform injects environment variables `INPUT_FOLDER` and `OUTPUT_FOLDER`. The service reads files from the former and writes results to the latter.

### The "Entrypoint Magic" (entrypoint.sh)
Data persistence in Osparc relies on volume mounting. Because these volumes are created by the host system, they often have permissions that conflict with the internal `scu` user.
1.  **Start as Root**: The container starts as root.
2.  **Fix Permissions**: The script inspects the mounted `INPUT_FOLDER` and `OUTPUT_FOLDER`. It dynamically changes the UID/GID of the `scu` user to match the folder ownership.
3.  **Drop Privileges**: It then switches execution to the `scu` user (`su scu ...`) to run the actual application.
*This mechanism prevents the common "Permission Denied" errors when writing outputs.*

---

## 2. Advanced Architecture: The "Runner" Pattern
The osparc-python-runner-machine-learning repository demonstrates how to manage multiple related services (e.g., PyTorch and TensorFlow support) within a single codebase.

### The Monorepo Structure
Instead of one repository per service, it uses a unified structure to generate two distinct docker images:
*   `/osparc-python-runner-pytorch`
*   `/osparc-python-runner-tensorflow`

### The "Base + Differentiation" Strategy
To minimize code duplication and image size, the build process is split:
1.  **Common Layer (`common/`)**:
    *   Inherits from a heavy, shared base (e.g., `nvidia/cuda`).
    *   Sets up the OS, the `scu` user, and global tools (like `uv` for fast Python installs).
    *   Contains the *generic* runner logic (main.py) which knows how to executing arbitrary scripts but doesn't have the libraries yet.
2.  **Specialized Layers**:
    *   These inherit from the *Common Layer*, not the raw OS image.
    *   They install only the specific libraries needed (e.g., `torch` vs `tensorflow`).
    *   This ensures that a fix to the permission logic in `common` automatically propagates to all flavors of the service.

### Automation is Key
Managing multiple metadata.yml and Dockerfile configurations requires automation. The repository uses `make` targets and the `ooil` utility to:
*   **Generate Run Scripts**: Automatically creates the `service.cli/run` scripts based on the metadata versions.
*   **Sync Docker Compose**: Generates `docker-compose` files that strictly match the metadata, ensuring that what you test locally matches what runs in production.
*   **Independent Versioning**: Allows the PyTorch service to be on version `1.2.0` while the TensorFlow service is on `2.5.0`, despite sharing a repo.

## 3. Best Practices Checklist
When creating or maintaining an Osparc service:

*   [ ] **Strict Input/Output**: Always read from `$INPUT_FOLDER` and write to `$OUTPUT_FOLDER`. Never hardcode paths.
*   [ ] **User Compliance**: Ensure your Dockerfile creates the `scu` (8004) user.
*   [ ] **Permission Handling**: Include and use the standard entrypoint.sh logic to fix volume permissions.
*   [ ] **Metadata Accuracy**: Use `make compose-spec` (or equivalent) to ensure your docker-compose.yml is generated from your metadata.yml.
*   [ ] **Wrapper Scripts**: Use a shell wrapper (execute.sh) to invoke your code. It provides a convenient place to debug environment variables before your code crashes.
*   [ ] **Base Images**: If managing multiple similar services, consider extracting the OS and permission setup into a common base Docker stage.


