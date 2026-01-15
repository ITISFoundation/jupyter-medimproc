# Jupyter MedImProc - Medical Image Processing Service

A comprehensive medical image processing service combining FreeSurfer and FSL toolchains, available in three variants:

- **jupyter-medimproc-jupyter**: Interactive JupyterLab environment
- **jupyter-medimproc-runner**: Headless runner (standard)
- **jupyter-medimproc-runner-slim**: Headless runner (optimized/smaller)

## Features

This service combines two powerful medical imaging toolchains:

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
- **PyTorch** (CPU): Deep learning framework for Synb0-DISCO

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
│   │   ├── install_freesurfer.sh  # FreeSurfer stack installation
│   │   └── install_fsl.sh         # FSL stack installation
│   └── entrypoint.sh              # Runner entrypoint
├── .gitlab-ci.yml        # GitLab CI configuration
├── Makefile              # Build automation
├── docker-compose.yml    # Local development
└── freesurfer_license.txt
```

## Building

The project uses GitLab CI for building on GitLab (due to memory requirements), but can also be built locally.

### Build Specific Variant

```bash
# Build jupyter variant
make build VARIANT=jupyter

# Build runner variant (standard)
make build VARIANT=runner

# Build runner-slim variant (optimized)
make build VARIANT=runner-slim
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
# Jupyter variant
make shell-jupyter

# Runner variant
make shell-runner

# Runner slim variant
make shell-runner-slim
```

## Testing

```bash
# Test specific variant
make test VARIANT=jupyter
make test VARIANT=runner
make test VARIANT=runner-slim
```

## GitLab CI/CD

The repository is configured for GitLab CI with three parallel build pipelines:

- `jupyter-medimproc-build` / `jupyter-medimproc-test`
- `runner-medimproc-build` / `runner-medimproc-test`
- `runner-medimproc-slim-build` / `runner-medimproc-slim-test`

Builds are triggered on:
- Branch pushes
- Merge requests
- Changes to relevant directories (`services/*/`, `common/`, `.gitlab-ci.yml`)

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

## Differences Between Variants

### jupyter-medimproc-jupyter
- Based on `itisfoundation/jupyter-math:2.0.9`
- Interactive JupyterLab interface
- Full installation (not optimized)
- User: `jovyan` (UID 1000)

### jupyter-medimproc-runner
- Based on `ubuntu:22.04`
- Headless runner
- Full installation (not optimized)
- User: `scu` (UID 8004)
- Includes entrypoint for runner integration

### jupyter-medimproc-runner-slim
- Based on `ubuntu:22.04`
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

## FreeSurfer License

A valid FreeSurfer license file (`freesurfer_license.txt`) must be present in the root directory for building. Get a free license at: https://surfer.nmr.mgh.harvard.edu/registration.html

## Version

Current version: **2.0.0**

## Maintenance

### Version Bumping

```bash
make version-patch  # 2.0.0 -> 2.0.1
make version-minor  # 2.0.0 -> 2.1.0
make version-major  # 2.0.0 -> 3.0.0
```

### Cleanup

```bash
# Remove built images
make clean

# Prune docker system
make prune
```

## Help

```bash
make help
```

## Migration Notes

This is version 2.0.0, which represents a significant restructuring:

- **Previous structure**: Separate services for freesurfer and fsl (6 services total)
- **New structure**: Unified services with 3 variants
- **CI**: Migrated from GitHub Actions to GitLab CI (no memory limits)
- **Installation**: Consolidated into single reusable script

## Authors

- Javier Garcia Ordonez (ordonez@zmt.swiss)
- ZMT Zurich MedTech AG

## License

See LICENSE file for details.
