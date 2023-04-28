# JupyterLab Dakota

This is the source code of the JupyterLab Medical Image Processing OSPARC service. It is mostly centered on MRI data, and contains the following packages:
  "[JupyterLab](https://jupyter.org/) with a variety of Medical Image Processing packages pre-installed, mostly centered on MRI data:
  - [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki), a comprehensive library of analysis tools for FMRI, MRI and DTI brain imaging data.
  - [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/), an open source neuroimaging toolkit for processing, analyzing, and visualizing human brain MR images-
  - [MRtrix3](https://www.mrtrix.org/) provides a set of tools to perform various types of diffusion MRI analyses.
  - [Spinal Cord Toolbox](https://spinalcordtoolbox.com/), a comprehensive, free and open-source set of command-line tools dedicated to the processing and analysis of spinal cord MRI data.
  - Python packages like [nibabel](https://nipy.org/nibabel/), [pyvista](https://docs.pyvista.org/version/stable/), [fsleyes](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes) and [cc3d](https://github.com/seung-lab/connected-components-3d#readme).
  
In the near future, [Synb0 Disco](https://github.com/MASILab/Synb0-DISCO#readme), for distortion correction of diffusion weighted MRI without reverse phase-encoding scans or field-maps, will also be added.

Commands from these packages can be run either from a terminal or from Jupyter Lab (using ! before the command) thus also offering visualization possibilities.
Either single commands can be run, or full .sh files.

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