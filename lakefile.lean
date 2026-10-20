import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "c8eb84b0803ce37c2419c20fd241b1977f2b911a"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "cb2a7709e8e5414f6a6ef7ec30c0bcb2199e5c36"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
