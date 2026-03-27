#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building W3.io whitepaper..."
pandoc \
  --metadata-file=metadata.yaml \
  chapters/*.md \
  --output=output/w3-whitepaper.pdf \
  --pdf-engine=tectonic \
  --syntax-highlighting=tango

echo "Output: output/w3-whitepaper.pdf"
