import Lake
open Lake DSL

package utemReborn

require ayxg from git
  "https://github.com/heartpunk/ayxg.git" @ "ab2bee80d559b864ca512058b75db75e2052d357"
require wruh from git
  "https://github.com/heartpunk/wruh.git" @ "e9931eaf74199fb7c66d2b1609a7e8aa502ed659"

@[default_target]
lean_lib UtemReborn where
  roots := #[`UtemReborn, `FutamuraCore, `FirstFutamura, `Reference]
