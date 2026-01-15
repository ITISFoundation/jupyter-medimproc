# Jupyter MedImProc - Medical Image Processing Service

> **Note**: This repository has been restructured in v2.0.0. For current documentation, please see [README_v2.md](README_v2.md)

This service provides medical image processing capabilities through three variants:

- **jupyter**: Interactive JupyterLab environment with FreeSurfer + FSL
- **runner**: Headless runner for automated processing (standard)
- **runner-slim**: Headless runner with optimized size

## Quick Start

```bash
# Build a variant
make build VARIANT=jupyter

# Run tests
make test VARIANT=jupyter

# Interactive shell
make shell VARIANT=jupyter
```

## Available Tools

All variants include:
- [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki) - Comprehensive library for FMRI, MRI and DTI analysis
- [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/) - Neuroimaging toolkit for brain MR images
- [MRtrix3](https://www.mrtrix.org/) - Diffusion MRI analysis tools
- [Synb0-DISCO](https://github.com/MASILab/Synb0-DISCO) - Distortion correction for diffusion MRI
- ANTs, ART, C3D and other processing tools

## Documentation

- **[README_v2.md](README_v2.md)** - Complete documentation
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[MIGRATION_v2.md](MIGRATION_v2.md)** - Migration guide from v1.x
- **[CHANGES.md](CHANGES.md)** - Change log and restructuring details

## Repository Structure

```
.
├── services/           # Docker service definitions
│   ├── jupyter/        # Interactive JupyterLab variant
│   ├── runner/         # Headless runner (standard)
│   └── runner-slim/    # Headless runner (optimized)
├── common/             # Shared scripts and entrypoint
│   ├── scripts/
│   └── entrypoint.sh
├── validation/         # Test data and outputs
├── Makefile           # Build system
├── docker-compose.yml # Local development
└── .gitlab-ci.yml     # CI/CD pipeline
```

## CI/CD

Builds are automated via GitLab CI with three parallel pipelines:
- `jupyter-medimproc-build` / `jupyter-medimproc-test`
- `runner-medimproc-build` / `runner-medimproc-test`
- `runner-medimproc-slim-build` / `runner-medimproc-slim-test`

## License

See [LICENSE](LICENSE) file.
