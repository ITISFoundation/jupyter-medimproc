#!/bin/bash
# =============================================================================
# Disk Usage Analysis Script
# =============================================================================
# Analyzes disk usage of major components in the Docker image.
# Run this inside the container to see actual sizes.
#
# Usage: ./analyze_disk_usage.sh
# =============================================================================

echo "=============================================="
echo "Disk Usage Analysis - jupyter-medimproc"
echo "=============================================="
echo ""

# Function to get directory size
get_size() {
    local path=$1
    if [ -e "$path" ]; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "N/A"
    fi
}

# Function to print row
print_row() {
    local component=$1
    local path=$2
    local size=$(get_size "$path")
    printf "%-25s %-40s %10s\n" "$component" "$path" "$size"
}

echo "Component                 Path                                     Size"
echo "------------------------- ---------------------------------------- ----------"

# MRtrix3
print_row "MRtrix3" "$HOME/mrtrix3"

# FreeSurfer
print_row "FreeSurfer (total)" "$FREESURFER_HOME"
print_row "  - bin/" "$FREESURFER_HOME/bin"
print_row "  - lib/" "$FREESURFER_HOME/lib"
print_row "  - subjects/" "$FREESURFER_HOME/subjects"
print_row "  - average/" "$FREESURFER_HOME/average"
print_row "  - mni/" "$FREESURFER_HOME/mni"

# Check for removed FreeSurfer components
echo ""
echo "FreeSurfer Removed Components (should be N/A):"
print_row "  - trctrain/" "$FREESURFER_HOME/trctrain"
print_row "  - diffusion/" "$FREESURFER_HOME/diffusion"
print_row "  - docs/" "$FREESURFER_HOME/docs"
print_row "  - matlab/" "$FREESURFER_HOME/matlab"
print_row "  - fsafd/" "$FREESURFER_HOME/fsafd"
print_row "  - tktools/" "$FREESURFER_HOME/tktools"

# FSL
echo ""
print_row "FSL (total)" "$FSLDIR"
print_row "  - bin/" "$FSLDIR/bin"
print_row "  - lib/" "$FSLDIR/lib"
print_row "  - data/" "$FSLDIR/data"
print_row "  - etc/" "$FSLDIR/etc"

# Check for removed FSL components
echo ""
echo "FSL Removed Components (should be N/A):"
print_row "  - fslpython/" "$FSLDIR/fslpython"
print_row "  - data/atlases/" "$FSLDIR/data/atlases"
print_row "  - data/possum/" "$FSLDIR/data/possum"
print_row "  - doc/" "$FSLDIR/doc"
print_row "  - tcl/" "$FSLDIR/tcl"

# ANTs
echo ""
print_row "ANTs v2.4.4" "$HOME/ants-2.4.4"
print_row "ANTs (osf.io duplicate)" "$HOME/ants"

# Synb0-DISCO
print_row "Synb0-DISCO" "$HOME/synb0-disco"

# c3d
print_row "c3d" "$HOME/c3d-1.0.0-Linux-x86_64"

# ART
print_row "ART" "$HOME/art"

# Python environment
echo ""
print_row "Python venv" "$HOME/.venv"

# PyTorch cache (if any)
print_row "PyTorch cache" "$HOME/.cache/torch"

echo ""
echo "=============================================="
echo "TOTAL DISK USAGE"
echo "=============================================="

echo ""
echo "Home directory total:"
du -sh $HOME 2>/dev/null

echo ""
echo "Breakdown of $HOME:"
du -sh $HOME/*/ 2>/dev/null | sort -hr | head -15

echo ""
echo "=============================================="
echo "COMPARISON WITH EXPECTED SIZES"
echo "=============================================="

# Calculate expected vs actual
echo ""
echo "Expected sizes (from optimization plan):"
echo "  FreeSurfer optimized: ~4-5 GB"
echo "  FSL optimized:        ~4-5 GB"
echo "  ANTs (single):        ~2.9 GB"
echo "  MRtrix3:              ~142 MB"
echo "  Synb0-DISCO:          ~430 MB"
echo ""

FS_SIZE=$(du -sb "$FREESURFER_HOME" 2>/dev/null | cut -f1 || echo 0)
FSL_SIZE=$(du -sb "$FSLDIR" 2>/dev/null | cut -f1 || echo 0)
ANTS_SIZE=$(du -sb "$HOME/ants-2.4.4" 2>/dev/null | cut -f1 || echo 0)

echo "Actual sizes:"
printf "  FreeSurfer: %.2f GB\n" $(echo "scale=2; $FS_SIZE / 1073741824" | bc 2>/dev/null || echo "N/A")
printf "  FSL:        %.2f GB\n" $(echo "scale=2; $FSL_SIZE / 1073741824" | bc 2>/dev/null || echo "N/A")
printf "  ANTs:       %.2f GB\n" $(echo "scale=2; $ANTS_SIZE / 1073741824" | bc 2>/dev/null || echo "N/A")
