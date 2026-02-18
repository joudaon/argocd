#!/bin/bash

echo "🧹 Deleting existing clusters (if any)..."
kind delete clusters -A || true

echo "🧹 Deleting files..."
rm -rf credentials.txt
rm -rf slave*