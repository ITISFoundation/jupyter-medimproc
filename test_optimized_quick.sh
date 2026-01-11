#!/bin/bash
# Quick validation test for optimized image
# Tests that all tools work without running the full pipeline

set -e

echo "========================================"
echo "Quick Validation Test for Optimized Image"
echo "========================================"
echo

# Test data paths
T1="/home/jovyan/work/workspace/matthew-pipeline/data/sub-26/ses-01/mri/t1w.nii.gz"
DWI="/home/jovyan/work/workspace/matthew-pipeline/data/sub-26/ses-01/dwi/dwi_raw.nii.gz"
BVAL="/home/jovyan/work/workspace/matthew-pipeline/data/sub-26/ses-01/dwi/bvals"
BVEC="/home/jovyan/work/workspace/matthew-pipeline/data/sub-26/ses-01/dwi/bvecs"

# Create test output directory
TEST_OUT="/home/jovyan/work/workspace/test_output"
mkdir -p "$TEST_OUT"

echo "1. Testing FreeSurfer tools..."
# Test mri_convert (quick)
if mri_convert "$T1" "$TEST_OUT/t1_converted.nii.gz" 2>&1 | tee "$TEST_OUT/mri_convert.log"; then
    echo "   ✓ FreeSurfer mri_convert works"
    ls -lh "$TEST_OUT/t1_converted.nii.gz"
else
    echo "   ✗ FreeSurfer mri_convert FAILED"
    exit 1
fi
echo

echo "2. Testing MRtrix3 tools..."
# Test mrinfo (quick)
if mrinfo "$DWI" 2>&1 | tee "$TEST_OUT/mrinfo.log" | head -20; then
    echo "   ✓ MRtrix3 mrinfo works"
else
    echo "   ✗ MRtrix3 mrinfo FAILED"
    exit 1
fi
echo

echo "3. Testing FSL tools..."
# Test fslinfo (quick)
if fslinfo "$T1" 2>&1 | tee "$TEST_OUT/fslinfo.log"; then
    echo "   ✓ FSL fslinfo works"
else
    echo "   ✗ FSL fslinfo FAILED"
    exit 1
fi
echo

echo "4. Testing ANTs tools..."
# Test antsRegistration help (quick)
if antsRegistration --help 2>&1 | head -10 | tee "$TEST_OUT/ants_help.log"; then
    echo "   ✓ ANTs tools available"
else
    echo "   ✗ ANTs tools FAILED"
    exit 1
fi
echo

echo "5. Testing Python environment..."
# Test Python packages
if /home/jovyan/.venv/bin/python -c "
import nibabel as nib
import numpy as np
import torch
print('nibabel version:', nib.__version__)
print('numpy version:', np.__version__)
print('torch version:', torch.__version__)
print('torch device:', 'cuda' if torch.cuda.is_available() else 'cpu')
" 2>&1 | tee "$TEST_OUT/python_test.log"; then
    echo "   ✓ Python environment works"
else
    echo "   ✗ Python environment FAILED"
    exit 1
fi
echo

echo "6. Testing Synb0-DISCO availability..."
if synb0-disco --help 2>&1 | head -20 | tee "$TEST_OUT/synb0_help.log"; then
    echo "   ✓ Synb0-DISCO available"
else
    echo "   ✗ Synb0-DISCO FAILED"
    exit 1
fi
echo

echo "========================================"
echo "✓ All tools validated successfully!"
echo "========================================"
echo "Test outputs saved to: $TEST_OUT"
ls -lh "$TEST_OUT"
