# Docker Image Optimization Strategy

**Target Image:** `simcore/services/dynamic/jupyter-medimproc:1.3.0`
**Current Size:** 32.4 GB
**Goal:** Reduce to ~15-20 GB or split into multiple services

---

## Executive Summary

Based on analysis of the Matthew pipeline and Docker image structure, three complementary optimization strategies are proposed:

| Strategy | Potential Savings | Complexity | Recommended |
|----------|------------------|------------|-------------|
| **A: Quick Wins** | 3-4 GB | Low | Yes (immediate) |
| **B: Minimal Installations** | 8-12 GB | Medium | Yes |
| **C: Multi-Service Split** | N/A (architecture change) | High | Consider for v2 |

---

## Strategy A: Quick Wins (Immediate Implementation)

### A1. Remove Duplicate ANTs Installation (-2.93 GB)

**Current State:** Two ANTs installations exist:
1. `osf.io` archive (17.5 MB) → `$HOME/ants/bin`
2. GitHub v2.4.4 (2.93 GB) → `$HOME/ants-2.4.4/bin/`

**The second installation overwrites ANTSPATH, making the first one orphaned but still present.**

**Solution:** Remove the osf.io ANTs installation entirely:

```dockerfile
# REMOVE these lines (currently around line 34-40):
# WORKDIR ${HOME}/ants
# RUN curl -fsSL https://osf.io/yswa4/download \
#   | tar xz --strip-components 1
# ENV ANTSPATH="$HOME/ants/bin"

# KEEP only the GitHub v2.4.4 installation (line 104+)
```

**Savings: ~2.93 GB (immediate)**

### A2. Clean MRtrix3 Build Dependencies (-45 MB)

The `-dev` packages remain in the final image. Combine build and cleanup:

```dockerfile
RUN apt-get -qq update \
  && apt-get install -yq --no-install-recommends \
    curl dc libeigen3-dev libfftw3-dev libgl1-mesa-dev libpng-dev \
    libqt5opengl5-dev libqt5svg5-dev libtiff5-dev qt5-default zlib1g-dev \
  && git clone https://github.com/MRtrix3/mrtrix3.git \
  && cd mrtrix3 && git checkout 3.0.4 \
  && ./configure && ./build -persistent -nopaginate \
  && rm -rf tmp \
  # Cleanup build dependencies, keep runtime libraries
  && apt-get purge -y libeigen3-dev libfftw3-dev libgl1-mesa-dev libpng-dev \
     libqt5opengl5-dev libqt5svg5-dev libtiff5-dev zlib1g-dev \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*
```

**Savings: ~45-100 MB**

### A3. Remove torchvision/torchaudio if Unused (-400 MB)

Synb0-DISCO only requires `torch`. Check if `torchvision` and `torchaudio` are needed:

```dockerfile
# Current:
RUN .venv/bin/pip --no-cache install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Optimized (if only torch is needed):
RUN .venv/bin/pip --no-cache install torch --index-url https://download.pytorch.org/whl/cpu
```

**Savings: ~400 MB (requires testing)**

---

## Strategy B: Minimal FreeSurfer & FSL Installations

### B1. FreeSurfer Minimal Installation (-5-7 GB)

**Current:** Full FreeSurfer 6.0.0 distribution (10.6 GB)

**Tools Actually Used by Pipeline:**
| Tool | Purpose | Required Directories |
|------|---------|---------------------|
| `recon-all` | Cortical reconstruction | Entire pipeline, `subjects/fsaverage` |
| `mri_convert` | Format conversion | `bin/`, `lib/` |
| `mri_surf2surf` | Surface resampling | `bin/`, `lib/` |

**FreeSurfer Directory Analysis:**

```
freesurfer/                   Size
├── subjects/                 ~4 GB  (sample data, can reduce)
│   └── fsaverage/            ~300 MB (REQUIRED for recon-all)
├── trctrain/                 ~1 GB  (TRACULA training data - REMOVABLE)
├── diffusion/                ~500 MB (REMOVABLE if not using tracula)
├── docs/                     ~200 MB (REMOVABLE)
├── average/                  ~1 GB  (atlases - partial removal possible)
├── matlab/                   ~100 MB (REMOVABLE)
└── bin/, lib/                ~3 GB  (REQUIRED - core binaries)
```

**Minimal FreeSurfer Implementation:**

```dockerfile
# Download full FreeSurfer and selectively remove components
RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv -C ${HOME} \
  # Remove unnecessary components
  && rm -rf ${HOME}/freesurfer/trctrain \
  && rm -rf ${HOME}/freesurfer/diffusion \
  && rm -rf ${HOME}/freesurfer/docs \
  && rm -rf ${HOME}/freesurfer/matlab \
  && rm -rf ${HOME}/freesurfer/fsafd \
  # Remove sample subjects but KEEP fsaverage
  && find ${HOME}/freesurfer/subjects -maxdepth 1 -type d ! -name 'subjects' ! -name 'fsaverage' -exec rm -rf {} + \
  # Remove unnecessary files in average/
  && rm -rf ${HOME}/freesurfer/average/mult-comp-cor
```

**Estimated Savings: 5-7 GB**

### B2. FSL Minimal Installation (-4-6 GB)

**Current:** Full FSL installation (9.84 GB)

**Tools Actually Used by Pipeline:**
| Tool | Purpose |
|------|---------|
| `eddy` / `eddy_openmp` | Eddy current correction |
| `flirt` | Linear registration |
| `topup` | EPI distortion correction (via Synb0) |
| `fast` | Tissue segmentation (used by eddy) |

**FSL Directory Analysis:**

```
fsl/                          Size
├── data/atlases/             ~3 GB  (MNI atlases - mostly REMOVABLE)
├── data/standard/            ~1 GB  (standard templates - keep minimal)
├── fslpython/                ~2 GB  (FSL Python environment - REMOVABLE if not using FSL Python tools)
├── bin/                      ~1 GB  (binaries - selective removal)
├── lib/                      ~500 MB (libraries - REQUIRED)
├── etc/, doc/                ~200 MB (REMOVABLE)
└── gui/, tcl/                ~500 MB (FSLView GUI - REMOVABLE)
```

**Approach 1: Post-install cleanup**

```dockerfile
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
  echo "" | python fslinstaller.py -d ${FSLDIR} && \
  # Remove unnecessary FSL components
  rm -rf ${FSLDIR}/data/atlases \
  && rm -rf ${FSLDIR}/doc \
  && rm -rf ${FSLDIR}/tcl \
  && rm -rf ${FSLDIR}/etc/matlab \
  && rm -rf ${FSLDIR}/data/possum \
  && rm -rf ${FSLDIR}/data/tbss \
  # Keep only essential standard templates
  && find ${FSLDIR}/data/standard -name "*.nii.gz" ! -name "MNI152*2mm*" -delete \
  # Remove unused binaries (be careful with this!)
  && rm -f ${FSLDIR}/bin/fsl_sub \
  && rm -f ${FSLDIR}/bin/lesion_* \
  && rm -f ${FSLDIR}/bin/*view* \
  && rm -f ${FSLDIR}/bin/*_gui
```

**Approach 2: Install only required FSL tools (Advanced)**

Use FSL's conda packages for targeted installation:

```dockerfile
# Alternative: Use FSL via conda for minimal install
RUN mamba install -c https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public/ -c conda-forge \
  fsl-eddy fsl-flirt fsl-topup fsl-fast
```

**Note:** The conda approach requires testing for compatibility.

**Estimated Savings: 4-6 GB**

---

## Strategy C: Multi-Service Architecture

Split the monolithic image into specialized services that communicate via o²S²PARC's pipeline mechanism.

### Proposed Service Split

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Current: jupyter-medimproc                      │
│                           32.4 GB                                   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Proposed Multi-Service Split                      │
├────────────────────┬───────────────────┬───────────────────────────┤
│                    │                   │                           │
│    Service 1       │    Service 2      │      Service 3            │
│ ─────────────────  │ ─────────────────  │ ─────────────────         │
│ FreeSurfer recon   │ Diffusion Pipeline│  TVB Export               │
│                    │                   │                           │
│ • FreeSurfer       │ • MRtrix3         │  • Python (numpy,         │
│   (minimal, 5 GB)  │ • FSL (minimal)   │    pyvista, nibabel)      │
│                    │ • Synb0-DISCO     │                           │
│                    │ • ANTs            │                           │
│                    │                   │                           │
│ Size: ~7-8 GB      │ Size: ~8-10 GB    │  Size: ~2 GB              │
│                    │                   │                           │
│ Input:             │ Input:            │  Input:                   │
│  • T1.nii.gz       │  • DWI data       │   • FreeSurfer outputs    │
│                    │  • FS outputs     │   • Diffusion outputs     │
│ Output:            │                   │                           │
│  • T1.mgz          │ Output:           │  Output:                  │
│  • aparc+aseg.mgz  │  • weights.txt    │   • connectivity.zip      │
│  • surfaces        │  • lengths.txt    │   • cortex surfaces       │
│                    │  • 5tt.mif.gz     │                           │
└────────────────────┴───────────────────┴───────────────────────────┘
```

### Pipeline Stages and Data Flow

```
Stage 1: Structural (FreeSurfer Service)
├── Input:  T1.nii.gz
├── Tool:   recon-all -all
├── Time:   6-12 hours
└── Output: subjects/$SUBJECT/mri/, subjects/$SUBJECT/surf/

Stage 2: Diffusion Preprocessing (Diffusion Service)
├── Input:  DWI.nii.gz, bvec, bval, T1.mgz, aparc+aseg.mgz
├── Tools:  MRtrix3 (denoise, degibbs), Synb0-DISCO, FSL eddy
├── Time:   2-4 hours
└── Output: post_preproc.mif.gz, response_*.txt

Stage 3: Tractography (Diffusion Service)
├── Input:  post_preproc.mif.gz, 5tt.mif.gz, avg_response_*.txt
├── Tools:  MRtrix3 (tckgen, tcksift2, tck2connectome)
├── Time:   1-3 hours
└── Output: weights.txt, lengths.txt, nodes.nii.gz

Stage 4: TVB Export (TVB Service)
├── Input:  FreeSurfer surfaces, connectivity matrices
├── Tools:  Python (numpy, pyvista, nibabel)
├── Time:   5-15 minutes
└── Output: connectivity.zip, cortex_*.zip
```

### Advantages of Multi-Service Architecture

| Advantage | Description |
|-----------|-------------|
| **Parallel Execution** | FreeSurfer can run while user prepares DWI data |
| **Resource Efficiency** | Only load services when needed |
| **Easier Updates** | Update FSL without rebuilding FreeSurfer |
| **Failure Isolation** | One service failing doesn't kill entire pipeline |
| **Reusability** | Use FreeSurfer service for other pipelines |
| **Smaller Pulls** | Users pull only needed services |

### Implementation Considerations

1. **Data Transfer:** o²S²PARC handles inter-service data transfer
2. **Checkpointing:** Each service outputs to persistent storage
3. **User Experience:** Can still expose as "one-click" pipeline via o²S²PARC meta-service
4. **Backward Compatibility:** Keep monolithic image as fallback

---

## Strategy D: S3 On-Demand Data Loading

For data that's needed only occasionally (atlases, templates), load from S3 at runtime.

### Candidates for S3 Storage

| Data | Size | Frequency of Use | S3 Candidate? |
|------|------|------------------|---------------|
| FSL atlases | 3 GB | Rarely | **Yes** |
| FreeSurfer average | 1 GB | Sometimes | **Yes** |
| FreeSurfer subjects (non-fsaverage) | 3.7 GB | Never | **Remove entirely** |
| Synb0-DISCO model weights | 375 MB | Every run | No (keep local) |

### Implementation Pattern

```bash
# download_atlas.sh - called at runtime if needed
download_if_missing() {
    local local_path="$1"
    local s3_url="$2"

    if [ ! -d "$local_path" ]; then
        echo "Downloading $(basename $local_path) from S3..."
        aws s3 cp "$s3_url" "$local_path" --recursive
    fi
}

# Usage in pipeline
download_if_missing "$FSLDIR/data/atlases" "s3://your-bucket/fsl-atlases/"
```

### S3 Architecture

```
s3://medimproc-data/
├── freesurfer/
│   ├── average/              # Atlases and templates
│   └── trctrain/             # TRACULA data (if ever needed)
├── fsl/
│   ├── atlases/              # MNI atlases
│   └── possum/               # POSSUM phantom data
└── models/
    └── synb0-disco/          # Neural network weights (optional)
```

### Pros and Cons of S3 Approach

| Pros | Cons |
|------|------|
| Smallest possible base image | Requires network access at runtime |
| Pay only for what you use | Added latency on first run |
| Easy to update data independently | Requires S3 bucket setup |
| Versioned data management | More complex error handling |

---

## Recommended Implementation Plan

### Phase 1: Quick Wins (1-2 days, saves ~3.5 GB)

1. Remove duplicate ANTs installation
2. Clean MRtrix3 build dependencies
3. Test removing torchvision/torchaudio

**Expected Result: 28-29 GB image**

### Phase 2: Minimal Installations (1-2 weeks, saves ~8-10 GB)

1. Create minimal FreeSurfer install script
2. Create minimal FSL install script
3. Test pipeline with reduced installations
4. Document which components were removed

**Expected Result: 18-22 GB image**

### Phase 3: Multi-Service Architecture (4-6 weeks)

1. Create FreeSurfer service Dockerfile
2. Create Diffusion service Dockerfile
3. Create TVB export service Dockerfile
4. Create o²S²PARC pipeline definition
5. Test full pipeline execution
6. Add S3 data loading for optional components

**Expected Result: 3 services, each 5-10 GB, total ~17-20 GB but more flexible**

---

## Detailed Component Analysis

### FreeSurfer 6.0.0 Breakdown

```
Component                     Size      Required for Pipeline?
─────────────────────────────────────────────────────────────
bin/                         1.5 GB    YES - core binaries
lib/                         1.0 GB    YES - libraries
subjects/fsaverage/          300 MB    YES - required by recon-all
average/                     1.0 GB    PARTIAL - keep MNI templates only
trctrain/                    1.0 GB    NO - TRACULA training data
diffusion/                   500 MB    NO - not using TRACULA
subjects/bert/               800 MB    NO - sample subject
subjects/cvs_avg35*/         2.0 GB    NO - CVS template subjects
docs/                        200 MB    NO
matlab/                      100 MB    NO
fsafd/                       300 MB    NO - FreeSurfer longitudinal
mni/                         500 MB    PARTIAL - keep mni/bin
python/                      200 MB    MAYBE - check dependencies
tktools/                     100 MB    NO - Tk GUI tools
```

### FSL Breakdown

```
Component                     Size      Required for Pipeline?
─────────────────────────────────────────────────────────────
bin/                         1.0 GB    PARTIAL - keep eddy, flirt, topup, fast
lib/                         500 MB    YES
fslpython/                   2.0 GB    NO - FSL Python tools not used
data/atlases/                3.0 GB    NO - not using atlas-based analysis
data/standard/               1.0 GB    PARTIAL - keep MNI152 2mm only
data/possum/                 200 MB    NO - POSSUM simulation
doc/                         100 MB    NO
tcl/                         200 MB    NO - Tcl GUI scripts
etc/flirtsch/                50 MB     YES - FLIRT schedules
etc/fslconf/                 <1 MB     YES - configuration
```

---

## Testing Plan

After any optimization, run full Matthew pipeline test:

```bash
# 1. Test FreeSurfer recon-all
recon-all -all -s test_subject -i /path/to/T1.nii.gz

# 2. Test diffusion preprocessing
bash diffusion_pipeline_pre_avg_resp_func.sh ...

# 3. Test tractography
bash diffusion_pipeline_post_avg_resp_func.sh ...

# 4. Test TVB export
python create_tvb_files.py ...

# 5. Verify outputs match reference run
diff -r output/ reference_output/
```

---

## Summary

| Strategy | Size Reduction | Effort | Risk |
|----------|---------------|--------|------|
| A: Quick Wins | 32.4 → 28-29 GB | Low | Low |
| B: Minimal Install | 28 → 18-22 GB | Medium | Medium |
| C: Multi-Service | 18-22 GB total, split | High | Medium |
| D: S3 Loading | Further 3-5 GB | Medium | Low |

**Recommended path:** A → B → C (incremental implementation)

---

## Implementation Files

The following files have been created to implement this optimization strategy:

| File | Description |
|------|-------------|
| [Dockerfile.optimized](Dockerfile.optimized) | Optimized Dockerfile with Phase 1 & 2 changes |
| [scripts/validate_optimized_install.sh](scripts/validate_optimized_install.sh) | Validates all required tools are available |
| [scripts/build_and_compare.sh](scripts/build_and_compare.sh) | Builds both images and compares sizes |
| [scripts/analyze_disk_usage.sh](scripts/analyze_disk_usage.sh) | Analyzes disk usage inside container |

### How to Build and Test

```bash
# Build both images and compare
./scripts/build_and_compare.sh

# Or build only the optimized image
./scripts/build_and_compare.sh --optimized-only

# Run validation inside the container
docker run --rm jupyter-medimproc:optimized bash /home/jovyan/scripts/validate_optimized_install.sh

# Analyze disk usage inside the container
docker run --rm jupyter-medimproc:optimized bash /home/jovyan/scripts/analyze_disk_usage.sh
```
