# JupyterLab Dakota

This is the source code of the JupyterLab Dakota Service developed at Sandia National Laboratories (US). 
The Dakota project delivers both state-of-the-art research and robust, usable software for optimization and UQ. Broadly, the Dakota software's advanced parametric analyses enable design exploration, model calibration, risk analysis, and quantification of margins and uncertainty with computational models. See the [project website](https://dakota.sandia.gov/) for more information.
Please visit [Citing Dakota](https://dakota.sandia.gov/content/citing-dakota) if you use this service in your research.
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