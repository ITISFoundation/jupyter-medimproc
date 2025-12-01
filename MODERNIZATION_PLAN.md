# Service Modernization Plan: JupyterLab Medical Image Processing

**Date:** December 1, 2025  
**Service Version:** 1.2.1  
**Maintainer:** ordonez

---

## Executive Summary

This document outlines a comprehensive plan to modernize the JupyterLab Medical Image Processing (MedImProc) service. The modernization focuses on documenting current software versions, updating to newer releases, optimizing build times, and reducing image size through improved Dockerfile practices.

---

## 1. Current Status Documentation

### 1.1 Base Image
- **Base:** `itisfoundation/jupyter-math:2.0.9`
- **Status:** Inherited from upstream, requires investigation
- **How to verify:** Check Docker Hub or source repository for jupyter-math

### 1.2 Medical Image Processing Software Versions

#### MRtrix3
- **Current Version:** 3.0.4 (Git checkout)
- **Installation Method:** Compiled from source (GitHub)
- **Repository:** https://github.com/MRtrix3/mrtrix3.git
- **How to check version:**
  ```bash
  docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 /bin/bash -c "mrinfo --version"
  ```
- **Location in Dockerfile:** Lines 23-27

#### FreeSurfer
- **Current Version:** 6.0.0
- **Installation Method:** Pre-compiled binary (FTP download)
- **Download URL:** ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz
- **How to check version:**
  ```bash
  docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 /bin/bash -c "source ${FREESURFER_HOME}/SetUpFreeSurfer.sh && freesurfer --version"
  ```
- **Location in Dockerfile:** Lines 41-49
- **Note:** Requires license file (freesurfer_license.txt)

#### FSL
- **Current Version:** Unknown (downloaded via installer.py)
- **Installation Method:** Python installer script
- **Download URL:** https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
- **How to check version:**
  ```bash
  docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 /bin/bash -c "cat ${FSLDIR}/etc/fslversion"
  ```
- **Location in Dockerfile:** Lines 57-63
- **Issue:** Version not explicitly pinned, downloads latest available at build time

#### ANTs (for Synb0-DISCO)
- **Current Version:** 2.4.4
- **Installation Method:** Pre-compiled binary (GitHub releases)
- **Download URL:** https://github.com/ANTsX/ANTs/releases/download/v2.4.4/ants-2.4.4-ubuntu-20.04-X64-gcc.zip
- **How to check version:**
  ```bash
  docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 antsRegistration --version
  ```
- **Location in Dockerfile:** Lines 105-107

#### c3d (Convert3D)
- **Current Version:** 1.0.0
- **Installation Method:** Pre-compiled binary (SourceForge)
- **Download URL:** https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz
- **How to check version:**
  ```bash
  docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 c3d -version
  ```
- **Location in Dockerfile:** Line 109

#### Synb0-DISCO
- **Current Version:** master branch (unpinned)
- **Installation Method:** Git clone from GitHub
- **Repository:** https://github.com/MASILab/Synb0-DISCO
- **How to check version:**
  ```bash
  docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 /bin/bash -c "cd ${HOME}/synb0-disco && git log -1 --format='%H %ci'"
  ```
- **Location in Dockerfile:** Lines 75-103
- **Issue:** Not pinned to specific version, uses master branch
- **Dependencies:** PyTorch (CPU version), installed via pip

#### Spinal Cord Toolbox (SCT)
- **Current Version:** 4.2.1
- **Status:** TEMPORARILY REMOVED (commented out in Dockerfile)
- **Reason:** GitHub building space issues (see lines 112-115)
- **Installation Method:** When enabled, downloads from GitHub releases
- **Download URL:** https://github.com/neuropoly/spinalcordtoolbox/archive/4.2.1.tar.gz
- **Note:** Adds ~1.5GB to image

#### ART ACPCdetect (for MRtrix3)
- **Current Version:** 2.0 (minified)
- **Installation Method:** Pre-compiled binary (OSF download)
- **Download URL:** https://osf.io/73h5s/download
- **Location in Dockerfile:** Lines 29-31

#### ANTs for MRtrix3
- **Current Version:** 2.3.4-2 (minified)
- **Installation Method:** Pre-compiled binary (OSF download)
- **Download URL:** https://osf.io/yswa4/download
- **Location in Dockerfile:** Lines 33-35
- **Note:** Different ANTs version than the one used for Synb0-DISCO

### 1.3 Python Packages
Defined in `requirements.in`:
- **nibabel** - Version: Unknown (not pinned)
- **pyvista** - Version: Unknown (not pinned)
- **PyOpenGL** - Version: Unknown (not pinned)
- **PyOpenGL_accelerate** - Version: Unknown (not pinned)
- **fsleyes** - Version: Unknown (not pinned)
- **connected-components-3d** - Version: Unknown (not pinned)
- **wxpython** - Installed separately with Ubuntu 20.04 wheels
- **attrdict** - Installed separately
- **PyTorch, torchvision, torchaudio** - CPU version (not in requirements.in)

**How to check versions:**
```bash
docker run simcore/services/dynamic/jupyter-medimproc:1.2.1 /bin/bash -c "source .venv/bin/activate && pip list"
```

**Generated file:** `requirements.txt` is compiled from `requirements.in` using pip-tools during build

### 1.4 System Dependencies
- Base OS: Ubuntu 20.04 (inherited from jupyter-math base image)
- Key libraries:
  - Qt5 (for MRtrix3 GUI components)
  - FFTW3 (for MRtrix3)
  - Eigen3 (for MRtrix3)
  - OpenGL/Mesa libraries
  - Various system utilities (curl, git, jq, etc.)

---

## 2. Version Investigation Plan

### 2.1 Priority 1: Critical Software (High Impact)

#### FSL
- **Action:** Determine current installed version
- **Method:** 
  1. Build current image
  2. Run: `cat ${FSLDIR}/etc/fslversion`
  3. Check FSL website for latest version: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
- **Latest Known:** FSL 6.0.7.x (as of 2024)
- **Update Strategy:** Pin to specific version by modifying installer script or using direct download URL

#### MRtrix3
- **Current:** 3.0.4
- **Latest Check:** https://github.com/MRtrix3/mrtrix3/releases
- **Latest Known:** 3.0.4 is latest stable release (as of check date)
- **Action:** Verify if any newer patches or releases are available

#### PyTorch
- **Current:** CPU version, unpinned
- **Action:** Pin to specific version
- **Latest Check:** https://pytorch.org/get-started/previous-versions/
- **Recommendation:** Use latest stable CPU-only version compatible with Python version in base image

### 2.2 Priority 2: Moderate Updates

#### FreeSurfer
- **Current:** 6.0.0 (from 2016)
- **Latest Check:** https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall
- **Latest Known:** FreeSurfer 7.4.x (as of 2024)
- **Consideration:** Major version update may require significant testing
- **Action:** Test FreeSurfer 7.x compatibility with existing pipelines

#### ANTs
- **Current:** 2.4.4 (for Synb0), 2.3.4-2 (for MRtrix3)
- **Latest Check:** https://github.com/ANTsX/ANTs/releases
- **Latest Known:** 2.5.x
- **Issue:** Two different versions installed for different purposes
- **Action:** Consolidate to single ANTs installation if possible

#### Synb0-DISCO
- **Current:** master branch (unpinned)
- **Action:** Pin to specific commit hash or tag
- **Latest Check:** https://github.com/MASILab/Synb0-DISCO/releases
- **Recommendation:** Use latest tagged release or pin commit hash

### 2.3 Priority 3: Python Packages

#### All Python packages in requirements.in
- **Action:** Create `requirements-versions.txt` with pinned versions
- **Method:**
  1. Build current image
  2. Export: `pip freeze > requirements-pinned.txt`
  3. Research latest versions on PyPI
  4. Test compatibility before updating

#### Spinal Cord Toolbox
- **Current:** 4.2.1 (DISABLED)
- **Latest Check:** https://github.com/neuropoly/spinalcordtoolbox/releases
- **Latest Known:** 6.x
- **Action:** Evaluate if re-enabling is needed; if so, update to latest version

---

## 3. Dockerfile Optimization Strategy

### 3.1 Multi-Stage Build Implementation

**Current Status:**
- Single-stage Dockerfile (current production)
- Incomplete multi-stage Dockerfile exists (MultiStage_Dockerfile)
- MultiStage_Dockerfile appears to be work-in-progress

**Proposed Multi-Stage Architecture:**

```dockerfile
# Stage 1: Base builder image with common build tools
FROM buildpack-deps:jammy AS base-builder

# Stage 2: MRtrix3 builder
FROM base-builder AS mrtrix3-builder
# Compile MRtrix3 with dependencies

# Stage 3: FreeSurfer downloader
FROM base-builder AS freesurfer-installer
# Download and extract FreeSurfer

# Stage 4: FSL installer
FROM base-builder AS fsl-installer
# Install FSL

# Stage 5: Synb0-DISCO setup
FROM base-builder AS synb0-installer
# Clone and setup Synb0-DISCO

# Stage 6: Python environment builder
FROM base AS python-builder
# Install Python packages in venv

# Stage 7: Final production image
FROM itisfoundation/jupyter-math:2.0.9 AS production
# Copy only necessary artifacts from previous stages
```

**Benefits:**
- Parallel builds for independent components
- Smaller final image (no build tools)
- Better layer caching
- Easier to maintain and update individual components

### 3.2 Layer Optimization Strategies

#### A. Combine RUN Commands
**Current Problem:** Multiple separate RUN commands create unnecessary layers

**Solution:**
```dockerfile
# Before (multiple layers)
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# After (single layer)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        package1 \
        package2 && \
    rm -rf /var/lib/apt/lists/*
```

#### B. Minimize Package Installation
- Use `--no-install-recommends` flag
- Remove package manager cache in same layer
- Audit installed packages for necessity

#### C. Optimize File Operations
- Download and extract in single RUN command
- Clean up temporary files in same layer
- Remove .git directories after clone

### 3.3 Image Size Reduction Tactics

#### Current Issues:
1. **FreeSurfer subjects directory:** Kept for fsaverage (needed for recon-all)
2. **Multiple ANTs installations:** 2.3.4-2 and 2.4.4 both present
3. **Build artifacts:** Some tools compiled from source leave build files
4. **Uncompressed downloads:** Large tarballs downloaded and not cleaned up
5. **Git history:** Full git clones with history

#### Proposed Solutions:

**1. FreeSurfer Optimization:**
```dockerfile
# Keep only essential subjects (fsaverage) and remove others
RUN rm -rf ${FREESURFER_HOME}/subjects/cvs_avg35* \
           ${FREESURFER_HOME}/subjects/bert \
           ${FREESURFER_HOME}/trctrain
```

**2. Consolidate ANTs:**
```dockerfile
# Use single ANTs version for all purposes
# Test compatibility first
```

**3. Shallow Git Clones:**
```dockerfile
# Before
RUN git clone https://github.com/MRtrix3/mrtrix3.git

# After
RUN git clone --depth 1 --branch 3.0.4 https://github.com/MRtrix3/mrtrix3.git && \
    cd mrtrix3 && rm -rf .git
```

**4. Cleanup Build Dependencies:**
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        # ... build dependencies ... && \
    # ... build software ... && \
    apt-get remove -y build-essential git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
```

### 3.4 Build Time Optimization

#### A. Use BuildKit
```dockerfile
# syntax=docker/dockerfile:1.4
# Enable BuildKit features
```

**Features to leverage:**
- `RUN --mount=type=cache` for package manager caches
- `RUN --mount=type=bind` for temporary file access
- Parallel stage execution

#### B. Optimize Download Steps
```dockerfile
# Use --link flag for COPY (BuildKit)
COPY --link --from=builder /app /app

# Cache pip downloads
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

#### C. Order Dockerfile for Cache Efficiency
- Put frequently changing commands last
- Install system packages before copying application code
- Copy requirements.txt before other files

### 3.5 Base Image Modernization

**Current:** `itisfoundation/jupyter-math:2.0.9`

**Considerations:**
- Verify Ubuntu version (appears to be 20.04)
- Check for newer jupyter-math versions
- Consider updating to Ubuntu 22.04 (Jammy) for:
  - Newer system packages
  - Better security patches
  - Modern library versions

**Action Items:**
1. Document jupyter-math base image contents
2. Check for jupyter-math updates
3. Test compatibility with newer base versions
4. Evaluate custom base image if jupyter-math is outdated

---

## 4. Implementation Roadmap

### Phase 1: Documentation & Assessment (Week 1-2)

**Tasks:**
1. ✅ Document current versions (this document)
2. ⬜ Build current image and extract all version information
3. ⬜ Create version inventory spreadsheet
4. ⬜ Research latest stable versions for all components
5. ⬜ Identify breaking changes between versions
6. ⬜ Document deprecated features

**Deliverables:**
- Complete version inventory
- Research report on updates
- Risk assessment document

### Phase 2: Dockerfile Refactoring (Week 3-4)

**Tasks:**
1. ⬜ Create new multi-stage Dockerfile
2. ⬜ Implement build optimization techniques
3. ⬜ Add version pinning for all components
4. ⬜ Add inline documentation/comments
5. ⬜ Create .dockerignore file
6. ⬜ Set up BuildKit configuration

**Deliverables:**
- Optimized Dockerfile
- Build time comparison report
- Image size comparison report

### Phase 3: Version Updates - Conservative (Week 5-6)

**Focus:** Update components with minimal breaking change risk

**Tasks:**
1. ⬜ Update Python packages (minor versions)
2. ⬜ Update ANTs to latest 2.5.x
3. ⬜ Update c3d if newer version exists
4. ⬜ Pin Synb0-DISCO to specific commit
5. ⬜ Pin PyTorch to specific version
6. ⬜ Update MRtrix3 if patches available

**Deliverables:**
- Updated Dockerfile (conservative)
- Test results for each component
- Rollback plan

### Phase 4: Version Updates - Major (Week 7-10)

**Focus:** Major version updates requiring extensive testing

**Tasks:**
1. ⬜ Test FreeSurfer 7.x compatibility
2. ⬜ Update FSL to latest version
3. ⬜ Evaluate Spinal Cord Toolbox re-enablement
4. ⬜ Update base image if applicable
5. ⬜ Run full integration tests
6. ⬜ Benchmark performance changes

**Deliverables:**
- Updated Dockerfile (with major updates)
- Comprehensive test suite results
- Performance comparison report
- Migration guide for users

### Phase 5: Validation & Documentation (Week 11-12)

**Tasks:**
1. ⬜ Run validation pipelines (Fariba_full_pipeline)
2. ⬜ Test all Jupyter notebooks
3. ⬜ Update README.md with new versions
4. ⬜ Create CHANGELOG.md
5. ⬜ Update docker-compose.yml
6. ⬜ Create upgrade guide for users
7. ⬜ Document known issues

**Deliverables:**
- Validated service image
- Updated documentation
- Release notes
- User upgrade guide

---

## 5. Testing Strategy

### 5.1 Component-Level Testing

For each updated component:
- ✅ Installation succeeds
- ✅ Version command works
- ✅ Basic functionality test
- ✅ Integration with other components

### 5.2 Integration Testing

**Test Cases:**
1. MRtrix3 pipeline with ANTs preprocessing
2. FreeSurfer recon-all workflow
3. FSL analysis pipeline
4. Synb0-DISCO distortion correction
5. Python package imports and basic operations
6. Jupyter notebook execution

### 5.3 Performance Testing

**Metrics:**
- Docker build time
- Image size (uncompressed/compressed)
- Container startup time
- Memory usage during typical workflows
- CPU utilization

### 5.4 Regression Testing

**Use existing validation:**
- Run existing validation scripts
- Compare outputs with previous version
- Ensure no functionality loss

---

## 6. Risk Assessment & Mitigation

### High Risk Updates

| Component | Risk | Impact | Mitigation |
|-----------|------|--------|------------|
| FreeSurfer 6→7 | High | High | Parallel testing; keep v6 fallback |
| FSL major update | Medium | High | Pin specific version; extensive testing |
| Base image update | Medium | High | Test in isolated environment first |
| PyTorch update | Low | Medium | Use CPU-only; test inference |

### Rollback Strategy

1. **Git branching:**
   - Create `modernization` branch
   - Keep `main` stable
   - Tag releases properly

2. **Docker image tags:**
   - Tag current version: `1.2.1-legacy`
   - Tag new version: `1.3.0`
   - Keep both available during transition

3. **Feature flags:**
   - Allow users to specify version preference
   - Provide migration period

---

## 7. Monitoring & Metrics

### Build Metrics

**Baseline (Current):**
- Build time: [TO BE MEASURED]
- Image size: [TO BE MEASURED]
- Number of layers: [TO BE MEASURED]

**Target (Optimized):**
- Build time: -30%
- Image size: -20%
- Number of layers: <50

### Success Criteria

1. ✅ All components updated to documented versions
2. ✅ Build time reduced by at least 20%
3. ✅ Image size reduced by at least 15%
4. ✅ All validation tests pass
5. ✅ No regression in functionality
6. ✅ Documentation complete and accurate

---

## 8. Maintenance Plan

### Version Tracking

**Create `VERSION_MANIFEST.txt` in image:**
```txt
# Medical Image Processing Service Version Manifest
# Generated: [BUILD_DATE]

SERVICE_VERSION=1.3.0
BASE_IMAGE=itisfoundation/jupyter-math:2.0.9

# Medical Imaging Software
MRTRIX3_VERSION=3.0.4
FREESURFER_VERSION=7.4.0
FSL_VERSION=6.0.7.3
ANTS_VERSION=2.5.0
C3D_VERSION=1.0.0
SYNB0_DISCO_VERSION=[commit_hash]

# Python Packages
PYTHON_VERSION=[version]
PYTORCH_VERSION=[version]
NIBABEL_VERSION=[version]
PYVISTA_VERSION=[version]
FSLEYES_VERSION=[version]
CC3D_VERSION=[version]
```

### Update Schedule

- **Monthly:** Check for security updates
- **Quarterly:** Review for minor version updates
- **Semi-annually:** Evaluate major version updates
- **Annually:** Full modernization review

### Documentation Requirements

For each update:
1. Update VERSION_MANIFEST.txt
2. Update CHANGELOG.md
3. Update README.md version references
4. Update docker-compose.yml labels
5. Tag git commit with version
6. Create GitHub release with notes

---

## 9. Quick Reference Commands

### Version Checking Commands

```bash
# Build and check current versions
docker build -t medimproc:test .
docker run --rm medimproc:test /bin/bash -c "
    echo 'MRtrix3:' && mrinfo --version
    echo 'FreeSurfer:' && cat \${FREESURFER_HOME}/build-stamp.txt
    echo 'FSL:' && cat \${FSLDIR}/etc/fslversion
    echo 'ANTs:' && antsRegistration --version
    echo 'Python packages:' && pip list
"

# Check image size
docker images medimproc:test --format "{{.Size}}"

# Check layer count
docker history medimproc:test --no-trunc | wc -l

# Analyze image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    wagoodman/dive:latest medimproc:test
```

### Build with BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build with cache
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t medimproc:test .

# Build with progress
docker build --progress=plain -t medimproc:test .
```

---

## 10. Resources & References

### Official Documentation
- [MRtrix3](https://mrtrix.readthedocs.io/)
- [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/fswiki)
- [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- [ANTs](http://stnava.github.io/ANTs/)
- [Synb0-DISCO](https://github.com/MASILab/Synb0-DISCO)
- [Spinal Cord Toolbox](https://spinalcordtoolbox.com/overview/introduction.html)

### Docker Best Practices
- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [BuildKit](https://docs.docker.com/build/buildkit/)

### Optimization Tools
- [dive - Docker image analyzer](https://github.com/wagoodman/dive)
- [hadolint - Dockerfile linter](https://github.com/hadolint/hadolint)
- [docker-slim](https://github.com/docker-slim/docker-slim)

---

## Appendix A: Sample Optimized Dockerfile Structure

```dockerfile
# syntax=docker/dockerfile:1.4

# ==============================================================================
# Stage 1: Base Builder
# ==============================================================================
FROM buildpack-deps:jammy AS base-builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        wget && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Stage 2: MRtrix3 Builder
# ==============================================================================
FROM base-builder AS mrtrix3-builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        libeigen3-dev \
        libfftw3-dev \
        libgl1-mesa-dev \
        libpng-dev \
        libqt5opengl5-dev \
        libqt5svg5-dev \
        libtiff5-dev \
        python3 \
        qt5-qmake \
        qtbase5-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/mrtrix3
RUN --mount=type=cache,target=/root/.cache \
    git clone --depth 1 --branch 3.0.4 https://github.com/MRtrix3/mrtrix3.git . && \
    ./configure && \
    ./build -persistent -nopaginate && \
    rm -rf .git tmp

# ==============================================================================
# Stage 3: Additional stages for other components...
# ==============================================================================

# ==============================================================================
# Final Production Stage
# ==============================================================================
FROM itisfoundation/jupyter-math:2.0.9 AS production
LABEL maintainer="ordonez"

# Copy only runtime components from builders
COPY --from=mrtrix3-builder /opt/mrtrix3 ${HOME}/mrtrix3

# ... continue with other components ...
```

---

## Appendix B: Migration Checklist

- [ ] Back up current working image
- [ ] Create git branch for modernization
- [ ] Document current versions
- [ ] Research updates for all components
- [ ] Create optimized Dockerfile
- [ ] Test build process
- [ ] Validate image size reduction
- [ ] Run component tests
- [ ] Run integration tests
- [ ] Update documentation
- [ ] Create release notes
- [ ] Tag release
- [ ] Deploy to test environment
- [ ] User acceptance testing
- [ ] Production deployment

---

**Document Version:** 1.0  
**Last Updated:** December 1, 2025  
**Next Review:** After Phase 1 completion
