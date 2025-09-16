#!/usr/bin/env bash
set -o errexit

echo "=== Starting Render Build Script ==="

# Install Ruby gems
bundle install --without development test --deployment --jobs 4 --retry 3

# Install JavaScript packages (if you use webpack, esbuild, etc.)
yarn install --frozen-lockfile

echo "=== Precompiling Assets ==="
bundle exec rails assets:precompile

echo "=== Cleaning Old Assets ==="
bundle exec rails assets:clean

echo "=== Build Completed Successfully ==="
# DELIBERATELY NOT RUNNING MIGRATIONS HERE