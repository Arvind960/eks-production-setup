#!/bin/bash

# GitHub Repository Setup Script
# Run this script to push your EKS scaling test suite to GitHub

echo "🚀 Setting up GitHub Repository for EKS Scaling Test Suite"
echo "========================================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "📥 Install it with: sudo apt install gh"
    echo "🔗 Or visit: https://cli.github.com/"
    exit 1
fi

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "🔐 Please login to GitHub CLI first:"
    echo "gh auth login"
    exit 1
fi

# Get repository name
read -p "📝 Enter repository name (default: eks-production-setup): " REPO_NAME
REPO_NAME=${REPO_NAME:-eks-production-setup}

# Get repository description
read -p "📝 Enter repository description (optional): " REPO_DESC
REPO_DESC=${REPO_DESC:-"Complete EKS HPA and ASG scaling test suite with timing measurements and resource calculations"}

# Ask for repository visibility
echo "🔒 Repository visibility:"
echo "1) Public"
echo "2) Private"
read -p "Choose (1 or 2, default: 1): " VISIBILITY
case $VISIBILITY in
    2) VISIBILITY_FLAG="--private" ;;
    *) VISIBILITY_FLAG="--public" ;;
esac

echo "📋 Repository Details:"
echo "Name: $REPO_NAME"
echo "Description: $REPO_DESC"
echo "Visibility: $([ "$VISIBILITY_FLAG" = "--private" ] && echo "Private" || echo "Public")"
echo

read -p "🚀 Create repository and push? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 0
fi

echo "🔄 Creating GitHub repository..."
gh repo create "$REPO_NAME" $VISIBILITY_FLAG --description "$REPO_DESC" --source=. --push

if [ $? -eq 0 ]; then
    echo "✅ Repository created successfully!"
    echo "🔗 Repository URL: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
    echo
    echo "📋 What's included:"
    echo "- Complete scaling test scripts"
    echo "- All HPA and ASG scenarios"
    echo "- Resource calculation guides"
    echo "- Comprehensive documentation"
    echo "- Terraform infrastructure code"
    echo
    echo "🚀 Ready to use! Clone with:"
    echo "git clone https://github.com/$(gh api user --jq .login)/$REPO_NAME.git"
else
    echo "❌ Failed to create repository"
    echo "🔧 Manual steps:"
    echo "1. Create repository on GitHub: https://github.com/new"
    echo "2. Add remote: git remote add origin https://github.com/YOUR_USERNAME/$REPO_NAME.git"
    echo "3. Push: git push -u origin main"
fi
