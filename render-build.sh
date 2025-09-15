#!/usr/bin/env bash
set -o errexit

echo "=== Starting Render Build Script ==="

# Install gems
bundle install

# Install JavaScript packages
yarn install

echo "=== Precompiling Assets ==="
bundle exec rails assets:precompile

echo "=== Cleaning Assets ==="
bundle exec rails assets:clean

echo "=== Build Completed Successfully ==="
# DELIBERATELY NOT RUNNING MIGRATIONS HERE