# Quick Start Guide

## Prerequisites

- Docker installed and running
- FreeSurfer license file (`freesurfer_license.txt`) in root directory
- For GitLab CI: GitLab account with registry access

## 1. Clone Repository

```bash
git clone <repository-url>
cd jupyter-medimproc
```

## 2. Add FreeSurfer License

Place your `freesurfer_license.txt` in the root directory. Get a free license at:
https://surfer.nmr.mgh.harvard.edu/registration.html

## 3. Build Your Preferred Variant

### Option A: Interactive Jupyter Environment

```bash
make build VARIANT=jupyter
```

**Use case**: Interactive analysis, visualization, notebook development

### Option B: Headless Runner (Standard)

```bash
make build VARIANT=runner
```

**Use case**: Production pipelines, automated processing, full feature set

### Option C: Headless Runner (Slim)

```bash
make build VARIANT=runner-slim
```

**Use case**: Production pipelines with space constraints, optimized size

## 4. Test the Build

```bash
make test VARIANT=jupyter  # or runner, or runner-slim
```

## 5. Run Locally

### Interactive Shell

```bash
# Open a shell in the container
make shell VARIANT=jupyter
```

### Using Docker Compose

```bash
# Start services
docker-compose up -d jupyter

# Access JupyterLab
# Open browser to: http://localhost:8888

# Stop services
docker-compose down
```

## Common Use Cases

### Case 1: Interactive Data Analysis

```bash
# Build jupyter variant
make build VARIANT=jupyter

# Start with docker-compose
docker-compose up -d jupyter

# Access at http://localhost:8888
# Both FreeSurfer and FSL commands available in notebooks/terminals
```

### Case 2: Automated Pipeline Processing

```bash
# Build runner variant
make build VARIANT=runner

# Run with mounted data
docker run -v /path/to/input:/input \
           -v /path/to/output:/output \
           -e INPUT_FOLDER=/input \
           -e OUTPUT_FOLDER=/output \
           jupyter-medimproc-runner:latest
```

### Case 3: Production with Size Constraints

```bash
# Build slim variant (smaller size)
make build VARIANT=runner-slim

# Deploy and run
docker run -v /path/to/input:/input \
           -v /path/to/output:/output \
           jupyter-medimproc-runner-slim:latest
```

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
  /input  → Your input data
  /output → Your results
```

## Troubleshooting

### Build Fails with "Out of Memory"

**Solution**: Use GitLab CI (designed for this)

```bash
# Push to GitLab (if mirrored)
git push gitlab main

# Or increase Docker memory locally
# Docker Desktop → Settings → Resources → Memory: 16GB+
```

### FreeSurfer License Error

**Symptom**: `ERROR: FreeSurfer license file not found`

**Solution**: 
```bash
# Ensure license file exists
ls -la freesurfer_license.txt

# Should be in root directory, not in subdirectories
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

## Next Steps

- See `README_v2.md` for full documentation
- See `MIGRATION_v2.md` if migrating from v1.x
- Check `.gitlab-ci.yml` for CI/CD setup
- Review `Makefile` for all available commands

## GitLab CI Setup (For Maintainers)

1. Mirror GitHub repo to GitLab
2. Configure CI/CD variables in GitLab:
   - `SC_CI_TESTING_REGISTRY`
   - `SC_CI_TESTING_REGISTRY_USER`
   - `SC_CI_TESTING_REGISTRY_PASSWORD`
   - `SC_CI_MASTER_REGISTRY`
   - `SC_CI_MASTER_REGISTRY_USER`
   - `SC_CI_MASTER_REGISTRY_PASSWORD`

3. Builds will run automatically on push

## Getting Help

```bash
# Show all make targets
make help

# Check Docker logs
docker logs <container-id>

# Inspect image
docker inspect jupyter-medimproc-jupyter:latest
```

## Performance Tips

1. **Cache Docker layers**: Use `make build` (not `make build-nc`) for faster rebuilds
2. **Choose right variant**: 
   - Development → `jupyter`
   - Production → `runner` or `runner-slim`
3. **Resource allocation**: Ensure Docker has enough memory (8GB minimum, 16GB+ recommended)
4. **Use GitLab CI**: For production builds (no memory limits)

---

**Ready to dive deeper?** Check out `README_v2.md` for comprehensive documentation.
