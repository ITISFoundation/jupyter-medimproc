# JupyterLab for Medical Image Processing (MedImProc)

This is the source code of the JupyterLab Medical Image Processing OSPARC service. It is mostly centered on MRI data, and contains the following packages:
  "[JupyterLab](https://jupyter.org/) with a variety of Medical Image Processing packages pre-installed, mostly centered on MRI data:
  - [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki), a comprehensive library of analysis tools for FMRI, MRI and DTI brain imaging data.
  - [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/), an open source neuroimaging toolkit for processing, analyzing, and visualizing human brain MR images-
  - [MRtrix3](https://www.mrtrix.org/) provides a set of tools to perform various types of diffusion MRI analyses.
  - [Spinal Cord Toolbox](https://spinalcordtoolbox.com/), a comprehensive, free and open-source set of command-line tools dedicated to the processing and analysis of spinal cord MRI data.
  - [Synb0 Disco](https://github.com/MASILab/Synb0-DISCO#readme), for distortion correction of diffusion weighted MRI without reverse phase-encoding scans or field-maps.
  - Python packages like [nibabel](https://nipy.org/nibabel/), [pyvista](https://docs.pyvista.org/version/stable/), [fsleyes](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes) and [cc3d](https://github.com/seung-lab/connected-components-3d#readme).

Commands from these packages can be run either from a terminal or from Jupyter Lab (using ! before the command) thus also offering visualization possibilities.
Either single commands can be run, or full .sh files.

____

## Service Modernization

**Current Version:** 1.2.1

A comprehensive modernization plan is available in [`MODERNIZATION_PLAN.md`](./MODERNIZATION_PLAN.md). This plan covers:

- **Current Software Versions:** Detailed inventory of all installed medical imaging software and their versions
- **Version Updates:** Investigation of newer versions and update strategies for all components
- **Dockerfile Optimization:** Multi-stage build implementation and layer optimization techniques
- **Image Size Reduction:** Strategies to reduce the Docker image size by ~15-20%
- **Build Time Optimization:** Techniques to reduce build time by ~20-30%
- **Implementation Roadmap:** Phased approach for modernization over 12 weeks
- **Testing & Validation:** Comprehensive testing strategy to ensure no regression

### Quick Version Reference

| Component | Current Version | Location in Dockerfile |
|-----------|----------------|------------------------|
| Base Image | jupyter-math:2.0.9 | Line 3 |
| MRtrix3 | 3.0.4 | Lines 23-27 |
| FreeSurfer | 6.0.0 | Lines 41-49 |
| FSL | Not pinned | Lines 57-63 |
| ANTs | 2.4.4 | Lines 105-107 |
| Synb0-DISCO | master (unpinned) | Lines 75-103 |
| Spinal Cord Toolbox | 4.2.1 (disabled) | Lines 112-115 |

For detailed version information, update strategies, and optimization techniques, please refer to the [Modernization Plan](./MODERNIZATION_PLAN.md).

____

## Information for developers of this **o<sup>2</sup>S<sup>2</sup>PARC** service
Building the docker image:

```shell
make build
```


Test the built image locally:

```shell
make run-local
```
Note that the `validation` directory will be mounted inside the service.


Raising the version can be achieved via one for three methods. The `major`,`minor` or `patch` can be bumped, for example:

```shell
make version-patch
```


If you already have a local copy of **o<sup>2</sup>S<sup>2</sup>PARC** running and wish to push data to the local registry:

```shell
make publish-local