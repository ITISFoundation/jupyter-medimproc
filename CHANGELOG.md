# Changelog

## [2.0.6] - 2022-05-08
- shell and kernel now use the same python interpreter
- fixes issue crashing when trusting notebooks
- fixes issue crashing when copying README.ipynb
- pick between only 2 available kernels

## [2.0.5] - 2022-03-03
- `~/work/workspace` is now the default working directory containing `~/work/workspace/README.ipynb`
- voila preview now works as expected
- replaced readme and which is now present inside 
- fixed: broken octave kernel and deactivated plugins
- fixed: broken LaTex compiler
- upgraded jupuyter-lab to v3.3.2

## [2.0.4] - 2022-02-02
- added `jupyterlab-lsp` and `python-lsp-server[all]` to make the python coding experience more user friendly

## [2.0.3] - 2022-01-28

- invalid notebooks will no longer cause the service to not start

## [2.0.2] - 2022-01-27

- changed scratch folder to workspace
- renamed default boot mode


## [2.0.1] - 2022-01-26

- changed voila to serve on 0.0.0.0 from localhost

## [2.0.0] - 2021-12-16

- updated to run via dynamic-sidecar
- output can be uploaded via the usage of symlinks
- security enhancements
- updated to python version 3.9.7
- updated to jupuyter-lab version 3.2.4
