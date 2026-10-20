import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "885e5d86ba5ef606aa65e81cbfaecaa98770f2df"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "840ec2b8f04849a00752e8335dcf008a103831f5"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
