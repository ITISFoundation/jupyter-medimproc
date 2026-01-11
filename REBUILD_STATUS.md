# Image Rebuild Status - Phase 2 Optimizations

**Date:** January 9, 2026, 11:30 AM  
**Status:** 🔄 IN PROGRESS

## Current Situation

### Existing Image Status
- **Image:** `jupyter-medimproc:optimized` 
- **Size:** 28 GB
- **Created:** January 9, 2026 01:00 AM
- **Phase 2 Cleanups Applied:** ❌ NO

**Verification:**
```bash
$ docker run --rm --entrypoint bash jupyter-medimproc:optimized -c \
  "ls -ld /home/jovyan/fsl/pkgs /home/jovyan/fsl/lib/python3.12 /home/jovyan/synb0-disco/.git"

drwxr-sr-x  39 root users  4096 Jan  8 23:57 /home/jovyan/fsl/lib/python3.12  ← Still exists (2.6 GB)
drwxr-sr-x 701 root users 94208 Jan  8 23:57 /home/jovyan/fsl/pkgs            ← Still exists (3.9 GB)  
drwxr-sr-x   8 root users  4096 Jan  8 23:58 /home/jovyan/synb0-disco/.git    ← Still exists (407 MB)
```

### Why the Rebuild Was Needed

The initial build with updated `Dockerfile.optimized` **used Docker's layer cache**. Even though the Dockerfile contained all Phase 2 cleanup commands, Docker found an existing cached layer with matching content and reused it, resulting in the same 28GB image without the new cleanups applied.

```dockerfile
# Phase 2 cleanups were in the Dockerfile but CACHED from old layer:
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py \
  && echo "" | python fslinstaller.py -d /home/jovyan/fsl \
  ...
  && rm -rf /home/jovyan/fsl/pkgs \              # ← These lines were CACHED
  && rm -rf /home/jovyan/fsl/lib/python3.* \    # ← Not executed
  && rm -rf /home/jovyan/synb0-disco/.git       # ← Not executed
```

### Current Rebuild

**Command:**
```bash
docker build --no-cache -f Dockerfile.optimized -t jupyter-medimproc:optimized-v2 .
```

**Progress:** Currently building MRtrix3 (Step 7/23) - 65/546 files compiled  
**Estimated Time:** 45-60 minutes total
- MRtrix3 compilation: ~10-15 minutes
- FreeSurfer download + cleanup: ~5 minutes  
- FSL installation + cleanup: ~30-40 minutes (longest step)
- Python packages + cleanup: ~5 minutes

**Log File:** [`build-no-cache.log`](build-no-cache.log)

### Expected Results After Rebuild

| Component | Current | After Phase 2 | Savings |
|-----------|---------|---------------|---------|
| FSL pkgs/ | 3.9 GB | 0 GB (removed) | **-3.9 GB** |
| FSL lib/python3.12 | 2.6 GB | 0 GB (removed) | **-2.6 GB** |
| FSL lib/ (other) | 670 MB | ~300 MB | **-370 MB** |
| Synb0-DISCO .git | 407 MB | 0 MB (removed) | **-407 MB** |
| Pip cache | 318 MB | 0 MB (removed) | **-318 MB** |
| **Total Savings** | | | **~7.6 GB** |

**Expected Final Size:** 28 GB - 7.6 GB = **~20.4 GB** ✅

## What Phase 2 Removes

### 1. FSL Conda Package Cache (3.9 GB)
```dockerfile
&& rm -rf ${FSLDIR}/pkgs
```
- Contains 701 directories with 123,668 cached conda package files
- Not needed after installation
- Safe to remove

### 2. FSL Python Environment (2.6 GB)
```dockerfile
&& rm -rf ${FSLDIR}/lib/python3.*
```
- Full Python 3.12 environment with all dependencies
- FSL binaries are pre-compiled and don't need Python runtime
- We have our own Python venv already

### 3. FSL Unnecessary Libraries (~370 MB)
```dockerfile
&& rm -rf ${FSLDIR}/lib/qt6 \
&& rm -f ${FSLDIR}/lib/libLLVM* \
&& rm -f ${FSLDIR}/lib/libclang* \
&& rm -rf ${FSLDIR}/lib/openvino* \
&& rm -rf ${FSLDIR}/lib/gcc
```
- GUI libraries (Qt6): not used in headless pipeline
- Compiler libraries (LLVM, clang, GCC): only needed for building, not runtime  
- OpenVINO: AI inference library not used by our pipeline

### 4. Synb0-DISCO .git Directory (407 MB)
```dockerfile
&& rm -rf ${HOME}/synb0-disco/.git
```
- Git history and objects
- Not needed for running the pipeline
- Only source code is required

### 5. Pip Cache (318 MB)
```dockerfile
&& rm -rf ${HOME}/.cache/pip
```
- Downloaded package files
- Not needed after installation

## Testing Plan After Rebuild

Once `jupyter-medimproc:optimized-v2` is built:

### 1. Verify Image Size
```bash
docker images jupyter-medimproc:optimized-v2
# Expected: ~20-21 GB
```

### 2. Verify Cleanups Applied
```bash
docker run --rm --entrypoint bash jupyter-medimproc:optimized-v2 -c \
  "ls -ld /home/jovyan/fsl/pkgs /home/jovyan/fsl/lib/python3.12 2>&1"
# Expected: "No such file or directory" for both
```

### 3. Critical: Test FSL Tools Still Work
```bash
# Test eddy (most important for pipeline)
docker run --rm jupyter-medimproc:optimized-v2 eddy_openmp --help

# Test flirt
docker run --rm jupyter-medimproc:optimized-v2 flirt -version

# Test topup  
docker run --rm jupyter-medimproc:optimized-v2 topup --help
```

**⚠️ IMPORTANT:** If FSL tools fail after removing Python environment, we may need to:
- Keep minimal Python runtime libraries
- Or use FSL's individual tool conda packages instead of full installer

### 4. Run Quick Validation
```bash
docker run --rm \
  -v "$PWD/tests:/home/jovyan/work/workspace" \
  --entrypoint bash \
  jupyter-medimproc:optimized-v2 \
  /home/jovyan/test_quick.sh
```

### 5. Run Matthew's Pipeline (if tests pass)
```bash
docker compose -f docker-compose-optimized.yml up -d
# Update image name in compose file to optimized-v2 first
docker exec -it <container> bash /home/jovyan/work/workspace/matthew-pipeline/run_pipeline_matthew.sh
```

## Monitoring Build Progress

Check build progress:
```bash
# View last 30 lines of log
tail -30 /home/ordonez/osparc-services/jupyter-medimproc/build-no-cache.log

# Follow build in real-time
tail -f /home/ordonez/osparc-services/jupyter-medimproc/build-no-cache.log | grep -E "(Step|DONE|Installing)"

# Check which step is running
grep -E "^#[0-9]+ \[[0-9]+/23\]" /home/ordonez/osparc-services/jupyter-medimproc/build-no-cache.log | tail -1
```

## Rollback Plan

If FSL tools don't work after Phase 2 cleanup:

### Option A: Selective Restoration
Keep only essential libs:
```dockerfile
# After removing python3.*, restore minimal runtime:
&& cp -r ${FSLDIR}/lib/python3.12/lib-dynload ${FSLDIR}/lib/ \
&& cp ${FSLDIR}/lib/python3.12/libpython3.12.so* ${FSLDIR}/lib/
```

### Option B: Use Current 28GB Image
The current `jupyter-medimproc:optimized` (28GB) is fully functional and can be used:
- All tools validated ✅
- Matthew's pipeline ready to run
- Only 4.4 GB larger than target

### Option C: Alternative FSL Installation
Build minimal FSL from individual packages (future improvement):
```dockerfile
RUN mamba install -c https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public/ \
  fsl-eddy fsl-flirt fsl-topup fsl-fast
# Results in ~2-3 GB FSL instead of 9.7 GB
```

## Timeline

- **11:28 AM:** Started `--no-cache` rebuild
- **11:32 AM:** MRtrix3 compilation in progress (65/546 files)
- **~11:45 AM:** Expected FreeSurfer download (Step 8)
- **~11:50 AM:** Expected FSL installation start (Step 11)
- **~12:30 PM:** Expected FSL installation complete
- **~12:40 PM:** Expected build completion

**Total Duration:** ~60-70 minutes

---

**Next Update:** Check progress in 30 minutes or when build completes.
