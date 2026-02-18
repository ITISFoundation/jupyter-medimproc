# Jupyter MedImProc - Medical Image Processing Service

A comprehensive medical image processing service combining FreeSurfer and FSL toolchains, available in three variants:

| Variant | Image Name | Use Case |
|---------|------------|----------|
| jupyter | `simcore/services/dynamic/jupyter-medimproc` | Interactive analysis, visualization, notebook development |
| runner | `simcore/services/comp/runner-medimproc` | Production pipelines, automated processing, full feature set |
| runner-slim | `simcore/services/comp/runner-medimproc-slim` | Production pipelines with space constraints, optimized size |

## Quick Start

### Prerequisites

- Docker installed and running
- FreeSurfer license file (`freesurfer_license.txt`) in root directory
- For GitLab CI: GitLab account with registry access

Get a free FreeSurfer license at: https://surfer.nmr.mgh.harvard.edu/registration.html

### Build and Run

```bash
# Clone repository
git clone <repository-url>
cd jupyter-medimproc

# Build a variant
make build VARIANT=jupyter      # Interactive Jupyter
make build VARIANT=runner       # Headless runner
make build VARIANT=runner-slim  # Optimized runner

# Run tests
make test VARIANT=jupyter

# Interactive shell
make shell VARIANT=jupyter

# Start with docker-compose
docker-compose up -d jupyter
# Access JupyterLab at http://localhost:8888
```

## Features

All variants include both toolchains:

### FreeSurfer Stack
- **FreeSurfer 6.0.0**: Neuroimaging toolkit for processing, analyzing, and visualizing brain MR images
- **MRtrix3 3.0.4**: Tools for diffusion MRI analysis
- **ART**: Advanced registration tools
- **ANTs**: Advanced normalization tools

### FSL Stack
- **FSL**: Comprehensive library of analysis tools for FMRI, MRI and DTI brain imaging data
- **Synb0-DISCO**: Distortion correction for diffusion weighted MRI
- **ANTs 2.4.4**: Advanced normalization tools (FSL variant)
- **C3D**: Image processing toolkit
- **PyTorch**: Deep learning framework for Synb0-DISCO (CPU version)

### Spinal Cord Toolbox
- **Spinal Cord Toolbox 7.2**: Comprehensive set of tools for processing and analysis of spinal cord MRI data (Available in `jupyter` and `runner` variants only)

## Repository Structure

```
.
├── services/
│   ├── jupyter/          # Interactive Jupyter variant
│   │   └── Dockerfile
│   ├── runner/           # Headless runner (standard)
│   │   └── Dockerfile
│   └── runner-slim/      # Headless runner (optimized)
│       └── Dockerfile
├── common/
│   ├── scripts/
│   │   ├── install_mrtrix3_art.sh  # FreeSurfer stack installation
│   │   └── install_fsl.sh         # FSL stack installation
│   └── entrypoint.sh              # Runner entrypoint
├── validation/           # Test data and outputs
├── tests/                # Test infrastructure
├── .gitlab-ci.yml        # GitLab CI configuration
├── Makefile              # Build automation
└── docker-compose.yml    # Local development
```

## Building

### Build Specific Variant

```bash
make build VARIANT=jupyter       # Build jupyter variant
make build VARIANT=runner        # Build runner variant (standard)
make build VARIANT=runner-slim   # Build runner-slim variant (optimized)
```

### Build All Variants

```bash
make build-all
```

### Build Without Cache

```bash
make build-nc VARIANT=jupyter
```

## Local Development

### Using Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Interactive Shell

```bash
make shell-jupyter       # Jupyter variant
make shell-runner        # Runner variant
make shell-runner-slim   # Runner slim variant
```

### Running Containers Directly

```bash
# Runner variant with mounted data
docker run -v /path/to/input:/input \
           -v /path/to/output:/output \
           -e INPUT_FOLDER=/input \
           -e OUTPUT_FOLDER=/output \
           simcore/services/comp/runner-medimproc:latest

# Slim variant
docker run -v /path/to/input:/input \
           -v /path/to/output:/output \
           simcore/services/comp/runner-medimproc-slim:latest
```

## Testing

```bash
# Test specific variant
make test VARIANT=jupyter
make test VARIANT=runner
make test VARIANT=runner-slim
```

### Using the Test Makefile

```bash
cd tests
make test-smoke VARIANT=jupyter    # Quick smoke tests
make test-all VARIANT=runner       # All tests including slow ones
make test-pipeline VARIANT=runner  # Full pipeline test (slow)
```

## Variant Differences

### simcore/services/dynamic/jupyter-medimproc
- Based on `itisfoundation/jupyter-math:2.0.9`
- Interactive JupyterLab interface
- Full installation (not optimized)
- User: `jovyan` (UID 1000)

### simcore/services/comp/runner-medimproc
- Based on `ubuntu:24.04`
- Headless runner
- Full installation (not optimized)
- User: `scu` (UID 8004)
- Includes entrypoint for runner integration

### simcore/services/comp/runner-medimproc-slim
- Based on `ubuntu:24.04`
- Headless runner
- **Optimized installation** (removes docs, examples, etc.)
- User: `scu` (UID 8004)
- Includes entrypoint for runner integration

### Optimization Details (Slim Variant)

The slim variant removes unnecessary files to reduce image size:

**FreeSurfer cleanup:**
- `subjects/` - Example subjects
- `docs/` - Documentation
- `trctrain/` - Training data
- `diffusion/` - Diffusion examples
- `matlab/` - MATLAB scripts

**FSL cleanup:**
- `data/standard/` - Standard templates
- `doc/` - Documentation
- `extras/src/` - Extra source files
- `src/` - Source files

## Environment Variables

### Build-time Variables
- `INSTALL_DIR`: Installation directory (default: `/usr/local` or `${HOME}`)
- `VENV_DIR`: Python virtual environment directory (default: `/home/jovyan/.venv`)
- `OPTIMIZED`: Enable optimizations (default: `false`, `true` for slim variant)

### Runtime Variables (Runner variants)
- `INPUT_FOLDER`: Input data directory (default: `/input`)
- `OUTPUT_FOLDER`: Output data directory (default: `/output`)
- `SC_BUILD_TARGET`: Build target (default: `runtime`)
- `FREESURFER_HOME`: FreeSurfer installation directory
- `FSLDIR`: FSL installation directory

## GitLab CI/CD

The repository is configured for GitLab CI with three parallel build pipelines:

- `jupyter-medimproc-build` / `jupyter-medimproc-test`
- `runner-medimproc-build` / `runner-medimproc-test`
- `runner-medimproc-slim-build` / `runner-medimproc-slim-test`

### Required Environment Variables

Configure these in GitLab CI/CD settings:

- `SC_CI_TESTING_REGISTRY` - Testing registry URL
- `SC_CI_TESTING_REGISTRY_USER` - Testing registry username
- `SC_CI_TESTING_REGISTRY_PASSWORD` - Testing registry password
- `SC_CI_MASTER_REGISTRY` - Master registry URL
- `SC_CI_MASTER_REGISTRY_USER` - Master registry username
- `SC_CI_MASTER_REGISTRY_PASSWORD` - Master registry password

### Pipeline Triggers

Builds are triggered on:
- Branch pushes
- Merge requests
- Changes to relevant directories (`services/*/`, `common/`, `.gitlab-ci.yml`)

## Example Commands Inside Container

Once inside the container (via shell or notebook):

```bash
# FreeSurfer commands
freesurfer --version
recon-all -h
mri_convert -h

# FSL commands
fsl --version
fslinfo
bet

# MRtrix3 commands
mrconvert -h
dwi2tensor -h

# Synb0-DISCO
pipeline_no_docker.sh -h

# Python (with PyTorch for Synb0-DISCO)
source ~/.venv/bin/activate  # Activate venv
python -c "import torch; print(torch.__version__)"
```

## Directory Structure for Data

### For Jupyter Variant

```
validation/
├── inputs/       # Mount your input data here
├── outputs/      # Results will appear here
└── workspace/    # Persistent workspace
```

### For Runner Variants

```
Mount points:
  /input  -> Your input data
  /output -> Your results
```

## Migration from v1.x

### Key Changes

1. **Unified Installation**: FreeSurfer and FSL are now installed together
2. **New Structure**: 3 variants instead of 6 separate services
3. **GitLab CI**: Builds now happen on GitLab due to memory requirements
4. **Simplified Dockerfiles**: All use common installation scripts

### Image Name Changes

```bash
# Old images
simcore/services/comp/jupyter-freesurfer:latest
simcore/services/comp/jupyter-fsl-synb0:latest

# New images
simcore/services/dynamic/jupyter-medimproc:latest
simcore/services/comp/runner-medimproc:latest
simcore/services/comp/runner-medimproc-slim:latest
```

### Build Command Changes

```bash
# Old way
make build SERVICE=jupyter-freesurfer

# New way
make build VARIANT=jupyter
```

### What's Preserved

- All FreeSurfer tools and versions
- All FSL tools and versions
- Environment variables
- Entrypoint behavior for runner
- FreeSurfer license requirement
- Synb0-DISCO pipeline script

### What's Changed

- Image names
- Build commands
- Directory structure
- CI platform (GitHub Actions -> GitLab CI)
- Both toolchains always included (can't separate anymore)

## Troubleshooting

### Build Fails with "Out of Memory"

**Solution**: Use GitLab CI (designed for this) or increase Docker memory locally:
- Docker Desktop -> Settings -> Resources -> Memory: 16GB+

### FreeSurfer License Error

**Symptom**: `ERROR: FreeSurfer license file not found`

**Solution**:
```bash
# Ensure license file exists in root directory
ls -la freesurfer_license.txt
```

### Container Starts but Commands Not Found

**Check environment**:
```bash
# Inside container
echo $FREESURFER_HOME
echo $FSLDIR
echo $PATH

# Re-source environments if needed
source $FREESURFER_HOME/SetUpFreeSurfer.sh
source $FSLDIR/etc/fslconf/fsl.sh
```

## Versioning

Current version: **1.4.1**

```bash
make version-patch  # 1.4.1 -> 1.3.5
make version-minor  # 1.4.1 -> 1.4.1
make version-major  # 1.4.1 -> 2.0.0
```

## Help

```bash
# Show all make targets
make help

# Check Docker logs
docker logs <container-id>

# Inspect image
docker inspect simcore/services/dynamic/jupyter-medimproc:latest
```

## Authors

- Javier Garcia Ordonez (ordonez@itis.swiss)
- ZMT Zurich MedTech AG

## License

See LICENSE file for details.
