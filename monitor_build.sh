#!/bin/bash
# Monitor docker build progress and report when complete

BUILD_LOG="/home/ordonez/osparc-services/jupyter-medimproc/build-no-cache.log"
IMAGE_NAME="jupyter-medimproc:optimized-v2"

echo "Monitoring build progress..."
echo "Log file: $BUILD_LOG"
echo "Target image: $IMAGE_NAME"
echo "---"

while true; do
    # Check if build is complete (look for "Successfully built" or error)
    if grep -q "Successfully built" "$BUILD_LOG" 2>/dev/null; then
        echo "✅ BUILD COMPLETED SUCCESSFULLY!"
        
        # Get final image size
        SIZE=$(docker images "$IMAGE_NAME" --format "{{.Size}}")
        echo "Image size: $SIZE"
        
        # Show image info
        docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        
        echo ""
        echo "Next steps:"
        echo "1. Verify cleanups: docker run --rm --entrypoint bash $IMAGE_NAME -c 'ls -ld /home/jovyan/fsl/pkgs 2>&1'"
        echo "2. Test FSL tools: docker run --rm $IMAGE_NAME eddy_openmp --help"
        echo "3. Run validation: docker run --rm -v \$PWD/tests:/home/jovyan/work/workspace --entrypoint bash $IMAGE_NAME /home/jovyan/test_quick.sh"
        
        break
        
    elif grep -q "ERROR" "$BUILD_LOG" 2>/dev/null; then
        echo "❌ BUILD FAILED - Check log for errors"
        tail -20 "$BUILD_LOG"
        break
        
    else
        # Show current progress
        CURRENT_STEP=$(grep -E "^#[0-9]+ \[[0-9]+/23\]" "$BUILD_LOG" 2>/dev/null | tail -1 | sed 's/#[0-9]* //')
        if [ -n "$CURRENT_STEP" ]; then
            echo "[$(date +%H:%M:%S)] $CURRENT_STEP"
        fi
        
        # Wait 60 seconds before checking again
        sleep 60
    fi
done
