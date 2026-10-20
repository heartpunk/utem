{
  description = "UTEM reborn: AYXG first Futamura projector contract";

  inputs = {
    ifrl.url = "github:heartpunk/ifrl/c69a322ec903672a2def1841be661eb6a339c89b";
    ayxg = {
      url = "github:heartpunk/ayxg/5d5ce159200dc4e7eeaf9965bdac6c857b2b7b3c";
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
