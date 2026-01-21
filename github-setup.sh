#!/bin/bash

echo "=== GitHub Repository Setup ==="
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
fi

# Add all files
echo "Adding files to git..."
git add .

# Commit
echo "Creating commit..."
git commit -m "Initial commit: EKS cluster with IRSA, Secrets Manager, EFS, and EBS"

# Rename README
echo "Setting up GitHub README..."
mv README_GITHUB.md README.md
git add README.md
git commit -m "Add GitHub README"

# Create GitHub repository (you'll need to do this manually or use gh CLI)
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Create GitHub repository:"
echo "   - Go to https://github.com/new"
echo "   - Repository name: EKS-IRSA-Secret-EFS"
echo "   - Description: Production-ready EKS with IRSA, Secrets Manager, EFS, and EBS"
echo "   - Public or Private: Your choice"
echo "   - DO NOT initialize with README"
echo ""
echo "2. Add remote and push:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/EKS-IRSA-Secret-EFS.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "Or if you have GitHub CLI installed:"
echo "   gh repo create EKS-IRSA-Secret-EFS --public --source=. --remote=origin --push"
echo ""
