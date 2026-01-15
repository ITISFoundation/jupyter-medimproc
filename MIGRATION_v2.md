# Migration Guide: v1.x to v1.3.0

## Overview of Changes

Version 1.3.0 represents a major restructuring of the jupyter-medimproc repository:

### Key Changes

1. **Unified Installation**: FreeSurfer and FSL are now installed together (no more split)
2. **New Structure**: 3 variants instead of 6 separate services
3. **GitLab CI**: Builds now happen on GitLab (mirrored from GitHub) due to memory requirements
4. **Simplified Dockerfiles**: All use common installation script
5. **New Directory Layout**: Consolidated into `services/` directory with 3 variants

## Old vs New Structure

### Old Structure (v1.x)
```
services/
├── jupyter-freesurfer/      → FreeSurfer only
├── jupyter-fsl-synb0/       → FSL only
├── runner-freesurfer/       → Headless FreeSurfer
├── runner-freesurfer-min/   → Optimized FreeSurfer
├── runner-fsl-synb0/        → Headless FSL
└── runner-fsl-synb0-min/    → Optimized FSL
```

### New Structure (v2.0)
```
services/
├── jupyter/         → Interactive with BOTH FreeSurfer + FSL
├── runner/          → Headless with BOTH (standard)
└── runner-slim/     → Headless with BOTH (optimized)
```

## Migration Steps

### For Developers

1. **Update Git Remote** (if mirroring to GitLab):
   ```bash
   git remote add gitlab <gitlab-url>
   ```

2. **Update Build Commands**:
   ```bash
   # Old way
   make build SERVICE=jupyter-freesurfer
   
   # New way
   make build VARIANT=jupyter
   ```

3. **Update Docker Compose**:
   - Old: `jupyter-medimproc` service
   - New: Choose from `jupyter`, `runner`, or `runner-slim`

4. **Update CI/CD**:
   - GitLab CI is now used instead of GitHub Actions
   - Configure GitLab registry credentials
   - Set up mirror from GitHub to GitLab

### For Users

1. **Image Names Changed**:
   ```bash
   # Old images
   simcore/services/comp/jupyter-freesurfer:latest
   simcore/services/comp/jupyter-fsl-synb0:latest
   
   # New images
   <registry>/jupyter-medimproc-jupyter:latest
   <registry>/jupyter-medimproc-runner:latest
   <registry>/jupyter-medimproc-runner-slim:latest
   ```

2. **All Tools Available**: You no longer need to choose between FreeSurfer and FSL - both are available in all variants

3. **Environment Variables**: Same as before for runner variants

## Build Configuration Changes

### Makefile

- **Old**: `make build SERVICE=<name>`
- **New**: `make build VARIANT=<variant>`

### Variants

- `VARIANT=jupyter` → Interactive JupyterLab (replaces jupyter-freesurfer + jupyter-fsl-synb0)
- `VARIANT=runner` → Headless standard (replaces runner-freesurfer + runner-fsl-synb0)
- `VARIANT=runner-slim` → Headless optimized (replaces runner-freesurfer-min + runner-fsl-synb0-min)

## GitLab CI Setup

### Required Environment Variables

Configure these in GitLab CI/CD settings:

- `SC_CI_TESTING_REGISTRY` - Testing registry URL
- `SC_CI_TESTING_REGISTRY_USER` - Testing registry username
- `SC_CI_TESTING_REGISTRY_PASSWORD` - Testing registry password
- `SC_CI_MASTER_REGISTRY` - Master registry URL
- `SC_CI_MASTER_REGISTRY_USER` - Master registry username
- `SC_CI_MASTER_REGISTRY_PASSWORD` - Master registry password

### Pipeline Structure

Each variant has its own build and test job:
- `jupyter-medimproc-build` + `jupyter-medimproc-test`
- `runner-medimproc-build` + `runner-medimproc-test`
- `runner-medimproc-slim-build` + `runner-medimproc-slim-test`

## Installation Script Changes

### Approach
- `common/scripts/install_freesurfer.sh` - FreeSurfer stack installation
- `common/scripts/install_fsl.sh` - FSL stack installation

### Benefits
- **Separate Docker layers**: Each toolchain in its own layer for better caching
- **Modular installation**: Can be modified independently
- **Consistent environment setup**: Both scripts use same environment variables
- **Support for OPTIMIZED flag**: Reduces image size when needed

## Breaking Changes

1. **Docker image names**: Changed from `simcore/services/comp/<name>` to `<registry>/jupyter-medimproc-<variant>`
2. **Service separation removed**: Can no longer build FreeSurfer-only or FSL-only images
3. **Directory structure**: Old 6-service structure → new 3-variant structure in `services/`
4. **CI platform**: GitHub Actions → GitLab CI
5. **Version number**: Reset to 1.3.0

## Compatibility Notes

### What's Preserved

✅ All FreeSurfer tools and versions
✅ All FSL tools and versions
✅ Environment variables
✅ Entrypoint behavior for runner
✅ FreeSurfer license requirement
✅ Synb0-DISCO pipeline script

### What's Changed

⚠️ Image names
⚠️ Build commands
⚠️ Directory structure
⚠️ CI platform
⚠️ Both toolchains always included (can't separate anymore)

### What's Improved

✨ Single unified installation
✨ Consistent environment across variants
✨ Simpler maintenance
✨ GitLab CI with better memory limits
✨ Reusable installation scripts

## Testing the Migration

### Quick Test

```bash
# Build and test jupyter variant
make build VARIANT=jupyter
make test VARIANT=jupyter
make shell VARIANT=jupyter

# Inside container, verify both toolchains
freesurfer --version
fsl --version
```

### Full Test

```bash
# Build all variants
make build-all

# Test each one
make test VARIANT=jupyter
make test VARIANT=runner
make test VARIANT=runner-slim

# Compare image sizes
docker images | grep jupyter-medimproc
```

## Rollback Plan

If you need to rollback to v1.x:

```bash
git checkout v1.3.0  # or your last v1.x tag
# Old build system will be available
```

## Support

For questions or issues:
- Check README_v2.md for full documentation
- Review .gitlab-ci.yml for CI configuration
- Examine services/*/Dockerfile for image details

## Timeline

- **v1.x**: Separate FreeSurfer and FSL services (deprecated)
- **v1.3.0**: Unified services with 3 variants (current)
- **Future**: Additional optimizations and toolchain updates
