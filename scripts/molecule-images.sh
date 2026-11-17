#!/bin/sh
# Builds the Molecule test images (systemd as PID 1) that the scenarios in
# extensions/molecule/ use with pre_build_image: true. Run once before
# `molecule test`, and again after a Dockerfile changes.
#
#   scripts/molecule-images.sh            # all images
#   scripts/molecule-images.sh rocky10    # one image
set -e
cd "$(dirname "$0")/../extensions/molecule/images"
images=${*:-$(ls)}
for image in $images; do
  docker build --pull -t "homelab-platform-test/$image:local" "$image"
done
