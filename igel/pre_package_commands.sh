#!/bin/bash
set -e

# Remove debug symbols and unnecessary files to reduce package size
find input/ -name "*.a" -delete
find input/ -name "*.la" -delete
find input/ -path "*/share/doc/*" -delete
find input/ -path "*/share/man/*" -delete
