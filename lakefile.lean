import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "3fee3ef8d1e056be85d97756acf9aceb1a634c49"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "4b4b7a578b7b84124cc0312ba73499fb43629522"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
