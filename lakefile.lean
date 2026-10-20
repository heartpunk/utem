import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "c7bd6ecc08a570c5b4a67643dcd33fc6c461bfec"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "03abf8bde75094d82aabd4789f18643656368d72"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
