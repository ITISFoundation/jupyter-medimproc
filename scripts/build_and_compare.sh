#!/bin/bash
# =============================================================================
# Build and Compare Script
# =============================================================================
# Builds both original and optimized Docker images and compares their sizes.
#
# Usage: ./build_and_compare.sh [--optimized-only] [--original-only]
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Image names
ORIGINAL_IMAGE="jupyter-medimproc:original"
OPTIMIZED_IMAGE="jupyter-medimproc:optimized"

# Parse arguments
BUILD_ORIGINAL=true
BUILD_OPTIMIZED=true

for arg in "$@"; do
    case $arg in
        --optimized-only)
            BUILD_ORIGINAL=false
            ;;
        --original-only)
            BUILD_OPTIMIZED=false
            ;;
        --help)
            echo "Usage: $0 [--optimized-only] [--original-only]"
            echo ""
            echo "Options:"
            echo "  --optimized-only  Build only the optimized image"
            echo "  --original-only   Build only the original image"
            exit 0
            ;;
    esac
done

cd "$PROJECT_DIR"

echo "=============================================="
echo "Docker Image Build and Comparison"
echo "=============================================="
echo ""

# Build original image
if [ "$BUILD_ORIGINAL" = true ]; then
    echo ">>> Building ORIGINAL image..."
    echo "----------------------------------------------"
    START_TIME=$(date +%s)
    docker build -t "$ORIGINAL_IMAGE" -f Dockerfile . 2>&1 | tee /tmp/build_original.log
    END_TIME=$(date +%s)
    ORIGINAL_BUILD_TIME=$((END_TIME - START_TIME))
    echo ""
    echo "Original image built in ${ORIGINAL_BUILD_TIME}s"
    echo ""
fi

# Build optimized image
if [ "$BUILD_OPTIMIZED" = true ]; then
    echo ">>> Building OPTIMIZED image..."
    echo "----------------------------------------------"
    START_TIME=$(date +%s)
    docker build -t "$OPTIMIZED_IMAGE" -f Dockerfile.optimized . 2>&1 | tee /tmp/build_optimized.log
    END_TIME=$(date +%s)
    OPTIMIZED_BUILD_TIME=$((END_TIME - START_TIME))
    echo ""
    echo "Optimized image built in ${OPTIMIZED_BUILD_TIME}s"
    echo ""
fi

# Compare sizes
echo "=============================================="
echo "SIZE COMPARISON"
echo "=============================================="

if [ "$BUILD_ORIGINAL" = true ]; then
    ORIGINAL_SIZE=$(docker image inspect "$ORIGINAL_IMAGE" --format='{{.Size}}' 2>/dev/null || echo "0")
    ORIGINAL_SIZE_HR=$(docker image inspect "$ORIGINAL_IMAGE" --format='{{.Size}}' 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "N/A")
    echo "Original:  $ORIGINAL_SIZE_HR ($ORIGINAL_SIZE bytes)"
fi

if [ "$BUILD_OPTIMIZED" = true ]; then
    OPTIMIZED_SIZE=$(docker image inspect "$OPTIMIZED_IMAGE" --format='{{.Size}}' 2>/dev/null || echo "0")
    OPTIMIZED_SIZE_HR=$(docker image inspect "$OPTIMIZED_IMAGE" --format='{{.Size}}' 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "N/A")
    echo "Optimized: $OPTIMIZED_SIZE_HR ($OPTIMIZED_SIZE bytes)"
fi

if [ "$BUILD_ORIGINAL" = true ] && [ "$BUILD_OPTIMIZED" = true ]; then
    if [ "$ORIGINAL_SIZE" -gt 0 ] && [ "$OPTIMIZED_SIZE" -gt 0 ]; then
        SAVINGS=$((ORIGINAL_SIZE - OPTIMIZED_SIZE))
        SAVINGS_HR=$(echo $SAVINGS | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "$SAVINGS bytes")
        PERCENT=$(echo "scale=1; ($SAVINGS * 100) / $ORIGINAL_SIZE" | bc 2>/dev/null || echo "N/A")
        echo ""
        echo "----------------------------------------------"
        echo "Savings:   $SAVINGS_HR ($PERCENT% reduction)"
    fi
fi

echo ""

# Validate optimized image
if [ "$BUILD_OPTIMIZED" = true ]; then
    echo "=============================================="
    echo "VALIDATING OPTIMIZED IMAGE"
    echo "=============================================="
    echo ""

    echo "Running validation script inside container..."
    docker run --rm "$OPTIMIZED_IMAGE" bash /home/jovyan/scripts/validate_optimized_install.sh || true
fi

# Layer analysis
echo ""
echo "=============================================="
echo "LAYER ANALYSIS"
echo "=============================================="

if [ "$BUILD_OPTIMIZED" = true ]; then
    echo ""
    echo ">>> Top 10 largest layers in OPTIMIZED image:"
    echo "----------------------------------------------"
    docker history "$OPTIMIZED_IMAGE" --format "{{.Size}}\t{{.CreatedBy}}" | \
        head -20 | \
        while read line; do
            size=$(echo "$line" | cut -f1)
            cmd=$(echo "$line" | cut -f2 | cut -c1-80)
            printf "%-10s %s\n" "$size" "$cmd"
        done
fi

echo ""
echo "=============================================="
echo "BUILD COMPLETE"
echo "=============================================="

if [ "$BUILD_ORIGINAL" = true ]; then
    echo "Original image:  $ORIGINAL_IMAGE"
fi
if [ "$BUILD_OPTIMIZED" = true ]; then
    echo "Optimized image: $OPTIMIZED_IMAGE"
fi

echo ""
echo "To run validation manually:"
echo "  docker run --rm $OPTIMIZED_IMAGE bash /home/jovyan/scripts/validate_optimized_install.sh"
echo ""
echo "To test the Matthew pipeline:"
echo "  docker run -v /path/to/data:/data $OPTIMIZED_IMAGE bash /data/run_pipeline_matthew.sh"
