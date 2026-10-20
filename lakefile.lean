import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "0bd5dc589687b14f79d5f962bf95ef637bb1a21c"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "f253eb4b83aa83c85ee9dd8bbe0813e4c36a3b34"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
