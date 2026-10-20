import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "c7bd6ecc08a570c5b4a67643dcd33fc6c461bfec"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "632a1daf5a6b101e005b3f7cdbb58db7d043128f"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
