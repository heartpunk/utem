import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "41ab0884267cafb496c982fa22f3e6dca97c009a"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "dc18f55b2545b018994cd65e179c3e6fec80b7c4"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
