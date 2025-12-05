#!/bin/bash
# Pre-commit checks (skips terraform plan)
# This script does not require AWS credentials

set -e

echo "Running Terraform validate..."
terraform validate || { echo "ERROR: Terraform validate failed" >&2; exit 1; }

echo "Running Terraform fmt -check..."
terraform fmt -check -recursive || {
    echo "ERROR: Terraform fmt -check failed. Run 'terraform fmt -recursive' to fix." >&2
    exit 1
}

if command -v tflint >/dev/null 2>&1; then
    echo "Running tflint..."
    tflint --init || true
    tflint || { echo "ERROR: tflint failed" >&2; exit 1; }
else
    echo "⚠ tflint not found (optional - install with: brew install tflint)"
fi

if command -v checkov >/dev/null 2>&1; then
    CHECKOV_VERSION=$(checkov --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    EXPECTED_VERSION="3.2.495"
    if [ "$CHECKOV_VERSION" != "$EXPECTED_VERSION" ] && [ "$CHECKOV_VERSION" != "unknown" ]; then
        echo "⚠ Warning: checkov version $CHECKOV_VERSION detected, but CI uses $EXPECTED_VERSION"
        echo "  Install with: pip install checkov==$EXPECTED_VERSION"
    fi
    echo "Running checkov security scan..."
    checkov -d . --framework terraform --quiet || {
        echo "ERROR: checkov security scan failed" >&2
        exit 1
    }
else
    echo "⚠ checkov not found (optional - install with: pip install checkov==3.2.495)"
fi

echo ""
echo "✓ All pre-commit checks passed! (plan skipped - use 'make test' for full test suite)"
