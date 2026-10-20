import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "5d5ce159200dc4e7eeaf9965bdac6c857b2b7b3c"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "16d77877512d97fad0622a7a6ac401cf8b2dd538"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
