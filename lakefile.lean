import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "4ca2cf940f9ecb3bcb5a021fe8dfb2d9b80c2ede"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "046186327e56f6043a03f51fca57420baf46b4c1"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
