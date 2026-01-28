# ============================================================================
# Runtime - Headless Runner MedImProc (Slim/Optimized Version)
# Copies all neuroimaging components from medimproc-common builder stages
# Creates optimized FSL and FreeSurfer in this layer for reduced image size
# ============================================================================
ARG VERSION

# Stage: Optimize FreeSurfer for slim build
FROM simcore/services/dynamic/medimproc-common:${VERSION} AS freesurfer-optimized
RUN cd /opt/freesurfer && \
    # Remove example subjects and data (already done but keep for clarity)
    rm -rf subjects docs && \
    # Remove toolkits not needed for headless structural recon
    rm -rf fsfast trctrain diffusion matlab tktools && \
    # Remove GUI tools (freeview, etc.) - not needed for headless runner
    rm -rf python/packages python/scripts/freeview* python/scripts/tkmedit* && \
    # Remove alternative models/atlases not used in default recon-all
    rm -rf models/DKTatlas* models/ExVivo* && \
    # Remove GUI libraries and tools (~1.2GB)
    rm -rf lib/cuda lib/qt lib/vtk lib/KWWidgets lib/tcltktixblt && \
    find bin/ -name "*_cuda" -delete 2>/dev/null || true && \
    find bin/ -name "*_gui*" -delete 2>/dev/null || true && \
    rm -f bin/freeview.bin bin/qdec.bin bin/mris_decimate_gui.bin 2>/dev/null || true && \
    # Remove multiple comparison correction data (~1.3GB) - not used in standard recon-all
    rm -rf average/mult-comp-cor && \
    # Remove alternative population templates (~1.5GB)
    rm -f average/SVIP_*.4dfp.* average/RLB700_atlas* average/*Schwartz* 2>/dev/null || true && \
    rm -rf average/Yeo_Brainmap_MNI152 && \
    # Remove alternative .gca files (keep only essential ones for recon-all)
    cd average && \
    find . -name "*.gca" ! -name "RB_all_2016-05-10.vc700.gca" \
    ! -name "RB_all_withskull_2016-05-10.vc700.gca" \
    ! -name "talairach_mixed_with_skull.gca" \
    -delete 2>/dev/null || true && \
    cd .. && \
    # Remove specialized segmentation tools not used in standard recon-all
    find bin/ -name "*hippocampus*" -delete 2>/dev/null || true && \
    find bin/ -name "*brainstem*" -delete 2>/dev/null || true && \
    find bin/ -name "*thal*" -delete 2>/dev/null || true && \
    # Clean up docs and license files (keep main license.txt)
    find . -type f -name "README*" -delete 2>/dev/null || true && \
    find . -type f -name "*.pdf" -delete 2>/dev/null || true && \
    echo "FreeSurfer optimized"

# Stage: Optimize FSL for slim build
FROM simcore/services/dynamic/medimproc-common:${VERSION} AS fsl-optimized
RUN cd /opt/medimproc/fsl && \
    # Remove unused data directories (~2.4GB)
    rm -rf data/first data/omm data/xtract_data data/possum data/feat5 doc extras/src src && \
    # Clean conda package cache (~2GB) - remove packages for deleted data/GUI components
    rm -rf pkgs/fsl-data_first_models_* && \
    rm -rf pkgs/fsl-data_omm-* && \
    rm -rf pkgs/fsleyes-* && \
    rm -rf pkgs/qt6-main-* && \
    rm -rf pkgs/vtk-base-* && \
    # Remove GUI/visualization Python packages (~1.1GB) - runner uses separate .venv
    rm -rf lib/python3.12/site-packages/fsleyes && \
    rm -rf lib/python3.12/site-packages/wx && \
    rm -rf lib/python3.12/site-packages/PySide6 && \
    rm -rf lib/python3.12/site-packages/vtkmodules && \
    rm -rf lib/python3.12/site-packages/plotly && \
    rm -rf lib/python3.12/site-packages/bokeh && \
    rm -rf lib/python3.12/site-packages/dash && \
    # Remove Jupyter/notebook packages (~150MB) - not needed in headless runner
    rm -rf lib/python3.12/site-packages/notebook && \
    rm -rf lib/python3.12/site-packages/nbclassic && \
    rm -rf lib/python3.12/site-packages/jupyterlab && \
    # Remove large ML/data packages (~400MB) - pipeline uses separate .venv
    rm -rf lib/python3.12/site-packages/sklearn && \
    rm -rf lib/python3.12/site-packages/skimage && \
    rm -rf lib/python3.12/site-packages/SimpleITK && \
    rm -rf lib/python3.12/site-packages/llvmlite && \
    rm -rf lib/python3.12/site-packages/numba && \
    rm -rf lib/python3.12/site-packages/statsmodels && \
    # Remove AWS/cloud packages (~150MB) - not needed
    rm -rf lib/python3.12/site-packages/botocore && \
    rm -rf lib/python3.12/site-packages/awscli && \
    # Remove pyfix (~130MB) - FIX ICA denoising not used in pipeline
    rm -rf lib/python3.12/site-packages/pyfix && \
    # Remove development/testing packages
    rm -rf lib/python3.12/site-packages/debugpy && \
    rm -rf lib/python3.12/site-packages/jedi && \
    rm -rf lib/python3.12/idlelib && \
    rm -rf lib/python3.12/tkinter && \
    rm -rf lib/python3.12/test && \
    # Remove scientific packages (pipeline uses separate .venv with specific versions)
    rm -rf lib/python3.12/site-packages/scipy lib/python3.12/site-packages/pandas \
    lib/python3.12/site-packages/matplotlib lib/python3.12/site-packages/numpy && \
    # Remove development files (~260MB)
    rm -rf include && \
    rm -rf lib/cmake && \
    rm -rf lib/vtk-9.3 && \
    find lib/ -name "*.a" -delete 2>/dev/null || true && \
    # Remove Qt GUI libraries (~100MB)
    rm -rf lib/qt6 && \
    find lib/ -name "libQt*" -delete 2>/dev/null || true && \
    find lib/ -name "libqt*" -delete 2>/dev/null || true && \
    # Remove compiler/build tools not needed at runtime (~1GB)
    rm -rf lib/gcc lib/libLLVM* lib/libclang* lib/openvino-* && \
    # Clean Python cache files
    find lib/python3.12 -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find lib/python3.12 -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    echo "FSL optimized"

# Stage: Final runtime
FROM ubuntu:24.04 AS runtime
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
COPY common/scripts/install_runtime_deps.sh /tmp/install_runtime_deps.sh
RUN chmod +x /tmp/install_runtime_deps.sh && \
    /tmp/install_runtime_deps.sh && \
    rm /tmp/install_runtime_deps.sh

# Setup SCU User
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

# Remove default ubuntu user to avoid UID 1000 conflict, then create SCU user
RUN userdel ubuntu && \
    useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

# Copy optimized components from optimization stages
COPY --from=fsl-optimized /opt/medimproc/fsl ${HOME}/fsl
COPY --from=freesurfer-optimized /opt/freesurfer ${HOME}/freesurfer

# Copy remaining components from fsl-optimized stage (which has all from medimproc-common)
COPY --from=fsl-optimized /opt/medimproc/ants-2.4.4 ${HOME}/ants-2.4.4
COPY --from=fsl-optimized /opt/medimproc/c3d-1.0.0-Linux-x86_64 ${HOME}/c3d-1.0.0-Linux-x86_64
COPY --from=fsl-optimized /opt/medimproc/.venv ${HOME}/.venv
COPY --from=fsl-optimized /opt/medimproc/synb0-disco ${HOME}/synb0-disco
COPY --from=fsl-optimized /opt/medimproc/mrtrix3 ${HOME}/mrtrix3
COPY --from=fsl-optimized /opt/medimproc/art ${HOME}/art

# Post-installation setup (license, pipeline)
COPY freesurfer_license.txt /tmp/freesurfer_license.txt
COPY pipeline_synb0_disco.sh /tmp/pipeline_synb0_disco.sh
COPY common/scripts/setup_freesurfer_license.sh /tmp/setup_freesurfer_license.sh
COPY common/scripts/setup_synb0_pipeline.sh /tmp/setup_synb0_pipeline.sh
RUN chmod +x /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh && \
    INSTALL_DIR=${HOME} /tmp/setup_freesurfer_license.sh && \
    INSTALL_DIR=${HOME} /tmp/setup_synb0_pipeline.sh && \
    rm /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh /tmp/freesurfer_license.txt /tmp/pipeline_synb0_disco.sh

# ============================================================================
# ENVIRONMENT VARIABLES - FreeSurfer
# ============================================================================
ENV FREESURFER_HOME=${HOME}/freesurfer \
    ANTSPATH="${HOME}/ants/bin" \
    ARTHOME="${HOME}/art" \
    PATH="${HOME}/mrtrix3/bin:${HOME}/ants/bin:${HOME}/art/bin:${PATH}"

ENV FSFAST_HOME=${FREESURFER_HOME}/fsfast \
    MINC_BIN_DIR=${FREESURFER_HOME}/mni/bin \
    MNI_DIR=${FREESURFER_HOME}/mni \
    PERL5LIB=${FREESURFER_HOME}/mni/share/perl5 \
    PATH=${FREESURFER_HOME}/bin:${MINC_BIN_DIR}:${PATH}

# ============================================================================
# ENVIRONMENT VARIABLES - FSL
# ============================================================================
ENV FSLDIR=${HOME}/fsl \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLTCLSH="${HOME}/fsl/bin/fsltclsh" \
    FSLWISH="${HOME}/fsl/bin/fslwish" \
    LD_LIBRARY_PATH="${HOME}/fsl/fslpython/envs/fslpython/lib/:${HOME}/fsl/lib:${LD_LIBRARY_PATH}" \
    PATH="${HOME}/fsl/share/fsl/bin:${HOME}/.venv/bin:${HOME}/ants-2.4.4/bin:${PATH}"

# ============================================================================
# RUNNER INTEGRATION
# ============================================================================
ENV SC_BUILD_TARGET="runtime" \
    INPUT_FOLDER="/input" \
    OUTPUT_FOLDER="/output"

# Entrypoint
COPY common/entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh

# Set environment for MNI tools from FreeSurfer
ENV PATH="/home/jovyan/freesurfer/mni/bin:${PATH}"

WORKDIR ${HOME}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD [ "/bin/bash" ]
