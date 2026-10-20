import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "ee82ce56fe2f5e6c337f671c74b1ad9098890e9e"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "7d5e03516e4334466809a5261cba395fdeb10eac"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
