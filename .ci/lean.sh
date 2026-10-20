#!/usr/bin/env bash
set -euo pipefail
lake update ayxg wruh
lake exe cache get
lake build UtemReborn
lake env lean -DwarningAsError=true tests/ProofAudit.lean
