# Refactoring Status

## Architecture Change: Decoupled Builds
To resolve CI disk space constraints (28 GB limit) and minimize image sizes, we have shifted from a "Common Base Image" strategy to a "Create-from-Script" strategy.

### Previous Strategy (Failed)
- **Common Base**: `jupyter` + `fsl`. (20 GB)
- **Headless**: `ubuntu` + `COPY --from=Common`. (15 GB)
- **Issue**: Building Headless required 35 GB disk space (Common + New Layer).

### New Strategy (Implemented)
- **Scripts**: `common/scripts/install_fsl.sh`, `common/scripts/install_freesurfer.sh`.
- **Headless Build**: `FROM ubuntu` + `RUN script`. (Max Disk: ~15 GB).
- **Interactive Build**: `FROM jupyter` + `RUN script`. (Max Disk: ~20 GB).
- **Result**: All builds stay comfortably under 28 GB.

## Services
| Service | Base | Tools | Status |
| :--- | :--- | :--- | :--- |
| `osparc-fsl-synb0` | Ubuntu 22.04 | FSL, Synb0, ANTs, C3D | **Refactored** |
| `osparc-fsl-synb0-min` | Ubuntu 22.04 | FSL (Stripped), Synb0, ANTs, C3D | **Refactored** |
| `jupyter-fsl-synb0` | Jupyter Math | FSL, Synb0, ANTs, C3D | **Refactored** |
| `osparc-freesurfer` | Ubuntu 22.04 | Freesurfer, Mrtrix3, ANTs, ART | **Refactored** |
| `osparc-freesurfer-min` | Ubuntu 22.04 | Freesurfer (Stripped), Mrtrix3, etc. | **Refactored** |
| `jupyter-freesurfer` | Jupyter Math | Freesurfer, Mrtrix3, ANTs, ART | **Refactored** |

## Usage
Run `make build SERVICE=<service-name>`
