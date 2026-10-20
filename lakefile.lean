import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "607e482f4f6ff846cf213971ab958f466df901b2"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "3cf9a80d71bd488ef0bf20177aac49a27021116f"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
