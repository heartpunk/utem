#!/usr/bin/env bash
set -euo pipefail
lake exe cache get
lake build UtemReborn
lake env lean -DwarningAsError=true tests/ProofAudit.lean
git diff --exit-code -- lake-manifest.json
