{
  description = "UTEM reborn: AYXG first Futamura projector contract";

  inputs = {
    ifrl.url = "github:heartpunk/ifrl/c69a322ec903672a2def1841be661eb6a339c89b";
    ayxg = {
      url = "github:heartpunk/ayxg/5106df06d92620da810c325b8779ce97a14f7f0e";
      inputs.ifrl.follows = "ifrl";
    };
    nixpkgs.follows = "ifrl/nixpkgs";
  };

  outputs = { nixpkgs, ayxg, ... }: {
    devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ]
      (system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = pkgs.mkShell {
          # Reuse AYXG's matching Lean toolchain and patched FloatLib source.
          inputsFrom = [ ayxg.devShells.${system}.ci ];
          shellHook = ''
            # WRUH's Lake configuration requires the same AYXG checkout.
            export WRUH_AYXG_SOURCE="$PWD/.lake/packages/ayxg"
          '';
        };
      });
  };
}
