#!/bin/bash
# Quick validation script for the new structure

set -e

echo "=================================================="
echo "Validation Script for jupyter-medimproc v2.0.0"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 missing"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/ exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ missing"
        return 1
    fi
}

# Validation
echo "Checking file structure..."
echo ""

# Critical files
check_file ".gitlab-ci.yml"
check_file "Makefile"
check_file "docker-compose.yml"
check_file "freesurfer_license.txt"
check_file "common/scripts/install_freesurfer.sh"
check_file "common/scripts/install_fsl.sh"
check_file "common/entrypoint.sh"

echo ""

# Service directories
check_dir "services"
check_dir "services/jupyter"
check_dir "services/runner"
check_dir "services/runner-slim"

echo ""

# Dockerfiles
check_file "services/jupyter/Dockerfile"
check_file "services/runner/Dockerfile"
check_file "services/runner-slim/Dockerfile"

echo ""

# Documentation
check_file "README.md"
check_file "README_v2.md"
check_file "MIGRATION_v2.md"
check_file "QUICKSTART.md"
check_file "CHANGES.md"

echo ""
echo "=================================================="
echo "Checking script permissions..."
echo "=================================================="
echo ""

# Check execute permissions
if [ -x "common/scripts/install_freesurfer.sh" ]; then
    echo -e "${GREEN}✓${NC} install_freesurfer.sh is executable"
else
    echo -e "${YELLOW}⚠${NC} install_freesurfer.sh is not executable"
    echo "  Run: chmod +x common/scripts/install_freesurfer.sh"
fi

if [ -x "common/scripts/install_fsl.sh" ]; then
    echo -e "${GREEN}✓${NC} install_fsl.sh is executable"
else
    echo -e "${YELLOW}⚠${NC} install_fsl.sh is not executable"
    echo "  Run: chmod +x common/scripts/install_fsl.sh"
fi

if [ -x "common/entrypoint.sh" ]; then
    echo -e "${GREEN}✓${NC} entrypoint.sh is executable"
else
    echo -e "${YELLOW}⚠${NC} entrypoint.sh is not executable"
    echo "  Run: chmod +x common/entrypoint.sh"
fi

echo ""
echo "=================================================="
echo "Checking Docker daemon..."
echo "=================================================="
echo ""

if docker info > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker is running"
    
    # Check Docker memory
    DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    if [ "$DOCKER_MEM" -gt 17179869184 ]; then  # 16GB in bytes
        echo -e "${GREEN}✓${NC} Docker has sufficient memory (>=16GB)"
    elif [ "$DOCKER_MEM" -gt 8589934592 ]; then  # 8GB in bytes
        echo -e "${YELLOW}⚠${NC} Docker has moderate memory (8-16GB)"
        echo "  Recommended: 16GB+ for building"
    else
        echo -e "${YELLOW}⚠${NC} Docker may have insufficient memory"
        echo "  Recommended: 16GB+ for building"
        echo "  Consider using GitLab CI for builds"
    fi
else
    echo -e "${RED}✗${NC} Docker is not running or not accessible"
    exit 1
fi

echo ""
echo "=================================================="
echo "Quick syntax check..."
echo "=================================================="
echo ""

# Check Makefile syntax
if make -n help > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Makefile syntax is valid"
else
    echo -e "${RED}✗${NC} Makefile has syntax errors"
fi

# Check docker-compose syntax
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} docker-compose.yml syntax is valid"
else
    echo -e "${RED}✗${NC} docker-compose.yml has syntax errors"
fi

# Check GitLab CI syntax (basic YAML check)
if command -v yamllint > /dev/null 2>&1; then
    if yamllint -d relaxed .gitlab-ci.yml > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} .gitlab-ci.yml YAML syntax is valid"
    else
        echo -e "${YELLOW}⚠${NC} .gitlab-ci.yml has YAML warnings"
    fi
else
    echo -e "${YELLOW}⚠${NC} yamllint not installed (skipping .gitlab-ci.yml check)"
    echo "  Install with: pip install yamllint"
fi

echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="
echo ""
echo "Structure validation complete!"
echo ""
echo "Next steps:"
echo "  1. Build: make build VARIANT=runner"
echo "  2. Test: make test VARIANT=runner"
echo "  3. Shell: make shell VARIANT=runner"
echo "  4. Build all: make build-all"
echo "  5. Push to GitLab to trigger CI"
echo ""
echo "For detailed documentation, see:"
echo "  - QUICKSTART.md"
echo "  - README_v2.md"
echo "  - MIGRATION_v2.md"
echo ""
