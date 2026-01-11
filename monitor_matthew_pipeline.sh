#!/bin/bash
# Monitor Matthew's pipeline execution

echo "====================================="
echo "Matthew's Pipeline Monitor"
echo "====================================="
echo ""

# Check if pipeline is running
docker exec jupyter-medimproc-jupyter-medimproc-1 bash -c '
cd /home/jovyan/work/workspace/matthew-pipeline

if [ -f pipeline.pid ]; then
    PID=$(cat pipeline.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✓ Pipeline Status: RUNNING (PID: $PID)"
        
        # Show running time
        START_TIME=$(ps -p $PID -o lstart=)
        echo "  Started: $START_TIME"
        
        # Show CPU and memory usage
        CPU_MEM=$(ps -p $PID -o %cpu,%mem,rss | tail -1)
        echo "  Resources: CPU/MEM% RSS(KB): $CPU_MEM"
    else
        echo "✗ Pipeline Status: NOT RUNNING"
        echo "  Check log for completion or errors"
    fi
else
    echo "✗ Pipeline Status: PID file not found"
fi

echo ""
echo "====================================="
echo "Recent Log Output (last 40 lines)"
echo "====================================="
tail -40 pipeline_run.log

echo ""
echo "====================================="
echo "Output Files Status"
echo "====================================="

# Check for key output files
echo "Diffusion outputs:"
if [ -d "/home/jovyan/work/workspace/matthew-pipeline/data/sub-26/sub-26_ses-01/dwi" ]; then
    ls -lh /home/jovyan/work/workspace/matthew-pipeline/data/sub-26/sub-26_ses-01/dwi/*.mif* 2>/dev/null | tail -10 || echo "  No .mif files yet"
fi

echo ""
echo "TVB outputs:"
if [ -d "/home/jovyan/work/workspace/matthew-pipeline/data/sub-26/sub-26_ses-01/TVB" ]; then
    ls -lh /home/jovyan/work/workspace/matthew-pipeline/data/sub-26/sub-26_ses-01/TVB/ 2>/dev/null || echo "  TVB directory empty"
else
    echo "  TVB directory not created yet"
fi
'
