import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "1bb41f03c920acb94ddf2e8813494c4f903a109e"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "62e2f61210a08b742099c8b10fb1284194d7d97c"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
