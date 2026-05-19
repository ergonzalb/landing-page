#!/bin/bash

# Landing Page Deployment Script
# This script will:
# 1. Initialize git repo
# 2. Create GitHub repository
# 3. Push code to GitHub
# 4. Deploy to Vercel

set -e

echo "🚀 Landing Page Deployment Script"
echo "=================================="
echo ""

# Check if tokens are set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable is not set"
    echo "Please run: export GITHUB_TOKEN='your_github_token'"
    exit 1
fi

if [ -z "$VERCEL_TOKEN" ]; then
    echo "❌ Error: VERCEL_TOKEN environment variable is not set"
    echo "Please run: export VERCEL_TOKEN='your_vercel_token'"
    exit 1
fi

# Get repo name (default: landing-page)
REPO_NAME=${1:-landing-page}
echo "📦 Repository name: $REPO_NAME"
echo ""

# Initialize git if not already
if [ ! -d .git ]; then
    echo "📝 Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: Landing page with lead capture"
fi

# Get GitHub username
echo "🔍 Getting GitHub username..."
GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep -o '"login": "[^"]*' | cut -d'"' -f4)

if [ -z "$GITHUB_USER" ]; then
    echo "❌ Error: Could not get GitHub username. Check your token."
    exit 1
fi

echo "👤 GitHub user: $GITHUB_USER"
echo ""

# Create GitHub repository
echo "📦 Creating GitHub repository..."
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$REPO_NAME\",\"description\":\"Modern landing page with lead capture popup\",\"private\":false}")

if echo "$RESPONSE" | grep -q "\"id\""; then
    echo "✅ Repository created successfully!"
else
    if echo "$RESPONSE" | grep -q "already exists"; then
        echo "⚠️  Repository already exists, continuing..."
    else
        echo "❌ Error creating repository:"
        echo "$RESPONSE" | grep "message"
        exit 1
    fi
fi

# Add remote and push
echo ""
echo "📤 Pushing code to GitHub..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"
git branch -M main
git push -u origin main --force

echo "✅ Code pushed to GitHub!"
echo "🔗 Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""

# Deploy to Vercel
echo "🚀 Deploying to Vercel..."

# Install Vercel CLI if not present
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

# Deploy
echo "📤 Deploying to Vercel..."
VERCEL_ORG_ID="" # Vercel will auto-detect
VERCEL_PROJECT_ID="" # Vercel will auto-detect

vercel --token "$VERCEL_TOKEN" --yes --prod

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Summary:"
echo "  GitHub: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "  Vercel: Check output above for deployment URL"
echo ""
echo "🎉 All done! Your landing page is live!"
