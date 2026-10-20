import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "fe01a093ea197b84e92f11f18804814d8f9a9448"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "d9bfd5e92e9bf96bf0eb9b6e3ad49a2ae5998eec"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
