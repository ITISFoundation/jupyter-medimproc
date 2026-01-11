#!/bin/bash
# =============================================================================
# Validation Script for Optimized Docker Image
# =============================================================================
# This script verifies that all tools required by the Matthew pipeline
# are available and functional after the optimization.
#
# Usage: ./validate_optimized_install.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

check_command() {
    local cmd=$1
    local package=$2
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}[PASS]${NC} $package: $cmd"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $package: $cmd NOT FOUND"
        ((FAIL_COUNT++))
        return 1
    fi
}

check_file() {
    local file=$1
    local desc=$2
    if [ -e "$file" ]; then
        echo -e "${GREEN}[PASS]${NC} $desc: $file"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $desc: $file NOT FOUND"
        ((FAIL_COUNT++))
        return 1
    fi
}

check_dir() {
    local dir=$1
    local desc=$2
    if [ -d "$dir" ]; then
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "${GREEN}[PASS]${NC} $desc: $dir ($size)"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $desc: $dir NOT FOUND"
        ((FAIL_COUNT++))
        return 1
    fi
}

check_removed() {
    local path=$1
    local desc=$2
    if [ ! -e "$path" ]; then
        echo -e "${GREEN}[PASS]${NC} Removed: $desc"
        ((PASS_COUNT++))
        return 0
    else
        local size=$(du -sh "$path" 2>/dev/null | cut -f1)
        echo -e "${YELLOW}[WARN]${NC} Still present: $desc ($size)"
        ((WARN_COUNT++))
        return 1
    fi
}

echo "=============================================="
echo "Validating Optimized Docker Image"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
echo ">>> MRtrix3 Tools (used in pipeline)"
echo "----------------------------------------------"
MRTRIX_CMDS=(
    "mrconvert"
    "dwidenoise"
    "mrdegibbs"
    "dwiextract"
    "mrmath"
    "mrinfo"
    "dwi2mask"
    "maskfilter"
    "mrcat"
    "dwifslpreproc"
    "dwi2response"
    "responsemean"
    "dwi2fod"
    "mtnormalise"
    "transformconvert"
    "mrtransform"
    "5ttgen"
    "tckgen"
    "tcksift2"
    "labelconvert"
    "tck2connectome"
)

for cmd in "${MRTRIX_CMDS[@]}"; do
    check_command "$cmd" "MRtrix3"
done

echo ""

# -----------------------------------------------------------------------------
echo ">>> FreeSurfer Tools (used in pipeline)"
echo "----------------------------------------------"
FS_CMDS=(
    "recon-all"
    "mri_convert"
    "mri_surf2surf"
)

for cmd in "${FS_CMDS[@]}"; do
    check_command "$cmd" "FreeSurfer"
done

echo ""
echo ">>> FreeSurfer Required Data"
echo "----------------------------------------------"
check_dir "$FREESURFER_HOME/subjects/fsaverage" "fsaverage (required by recon-all)"
check_file "$FREESURFER_HOME/license.txt" "FreeSurfer license"

echo ""
echo ">>> FreeSurfer Removed Components (should not exist)"
echo "----------------------------------------------"
check_removed "$FREESURFER_HOME/trctrain" "TRACULA training data"
check_removed "$FREESURFER_HOME/diffusion" "Diffusion toolkit"
check_removed "$FREESURFER_HOME/docs" "Documentation"
check_removed "$FREESURFER_HOME/matlab" "MATLAB scripts"
check_removed "$FREESURFER_HOME/fsafd" "Longitudinal tools"
check_removed "$FREESURFER_HOME/tktools" "Tk GUI tools"
check_removed "$FREESURFER_HOME/subjects/bert" "Sample subject: bert"

echo ""

# -----------------------------------------------------------------------------
echo ">>> FSL Tools (used in pipeline)"
echo "----------------------------------------------"
FSL_CMDS=(
    "eddy"
    "flirt"
    "topup"
    "fast"
)

for cmd in "${FSL_CMDS[@]}"; do
    check_command "$cmd" "FSL"
done

echo ""
echo ">>> FSL Required Data"
echo "----------------------------------------------"
check_dir "$FSLDIR/etc/flirtsch" "FLIRT schedules"
check_file "$FSLDIR/etc/fslconf/fsl.sh" "FSL configuration"

echo ""
echo ">>> FSL Removed Components (should not exist)"
echo "----------------------------------------------"
check_removed "$FSLDIR/fslpython" "FSL Python environment"
check_removed "$FSLDIR/data/atlases" "FSL atlases"
check_removed "$FSLDIR/data/possum" "POSSUM simulator"
check_removed "$FSLDIR/doc" "Documentation"
check_removed "$FSLDIR/tcl" "Tcl scripts"

echo ""

# -----------------------------------------------------------------------------
echo ">>> ANTs Tools (used by Synb0-DISCO)"
echo "----------------------------------------------"
ANT_CMDS=(
    "antsRegistration"
    "antsApplyTransforms"
    "N4BiasFieldCorrection"
)

for cmd in "${ANT_CMDS[@]}"; do
    check_command "$cmd" "ANTs"
done

echo ""
echo ">>> ANTs Duplicate Check"
echo "----------------------------------------------"
if [ -d "$HOME/ants" ] && [ -d "$HOME/ants-2.4.4" ]; then
    echo -e "${YELLOW}[WARN]${NC} Both ants/ and ants-2.4.4/ exist - duplicate installation!"
    ((WARN_COUNT++))
elif [ -d "$HOME/ants-2.4.4" ]; then
    echo -e "${GREEN}[PASS]${NC} Only ants-2.4.4/ exists (no duplicate)"
    ((PASS_COUNT++))
else
    echo -e "${RED}[FAIL]${NC} ANTs directory not found"
    ((FAIL_COUNT++))
fi

echo ""

# -----------------------------------------------------------------------------
echo ">>> Synb0-DISCO"
echo "----------------------------------------------"
check_command "synb0-disco" "Synb0-DISCO"
check_dir "$HOME/synb0-disco" "Synb0-DISCO directory"
check_dir "$HOME/synb0-disco/INPUTS" "Synb0-DISCO INPUTS"
check_dir "$HOME/synb0-disco/OUTPUTS" "Synb0-DISCO OUTPUTS"

echo ""

# -----------------------------------------------------------------------------
echo ">>> c3d (used by Synb0-DISCO)"
echo "----------------------------------------------"
check_command "c3d" "c3d"

echo ""

# -----------------------------------------------------------------------------
echo ">>> Python Environment"
echo "----------------------------------------------"
check_command "python" "Python"

# Check for torch (should exist)
if python -c "import torch" 2>/dev/null; then
    echo -e "${GREEN}[PASS]${NC} Python: torch module"
    ((PASS_COUNT++))
else
    echo -e "${RED}[FAIL]${NC} Python: torch module NOT FOUND"
    ((FAIL_COUNT++))
fi

# Check that torchvision is NOT installed (should be removed in optimized)
if python -c "import torchvision" 2>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Python: torchvision still installed (could be removed)"
    ((WARN_COUNT++))
else
    echo -e "${GREEN}[PASS]${NC} Python: torchvision removed (as expected)"
    ((PASS_COUNT++))
fi

# Check essential packages
PYTHON_PKGS=(
    "numpy"
    "nibabel"
    "pyvista"
    "scipy"
)

for pkg in "${PYTHON_PKGS[@]}"; do
    if python -c "import $pkg" 2>/dev/null; then
        echo -e "${GREEN}[PASS]${NC} Python: $pkg module"
        ((PASS_COUNT++))
    else
        echo -e "${RED}[FAIL]${NC} Python: $pkg module NOT FOUND"
        ((FAIL_COUNT++))
    fi
done

echo ""

# -----------------------------------------------------------------------------
echo ">>> ART (Automatic Registration Toolbox)"
echo "----------------------------------------------"
check_dir "$HOME/art" "ART directory"

echo ""

# -----------------------------------------------------------------------------
echo "=============================================="
echo "VALIDATION SUMMARY"
echo "=============================================="
echo -e "${GREEN}Passed:${NC}  $PASS_COUNT"
echo -e "${YELLOW}Warnings:${NC} $WARN_COUNT"
echo -e "${RED}Failed:${NC}  $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All required tools are available!${NC}"
    exit 0
else
    echo -e "${RED}Some required tools are missing. Pipeline may not work correctly.${NC}"
    exit 1
fi
