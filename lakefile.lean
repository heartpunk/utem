import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "5106df06d92620da810c325b8779ce97a14f7f0e"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "16d77877512d97fad0622a7a6ac401cf8b2dd538"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura]
