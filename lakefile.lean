import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "4d8620962ecaaadb2e3c44f1610323a759325377"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "168da5a731d17fdea230666c5ed67b6972af5f18"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
