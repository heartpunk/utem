{
  description = "UTEM reborn: AYXG first Futamura projector contract";

  inputs = {
    ifrl.url = "github:heartpunk/ifrl/128c222f0bf214f1716511c5a1ebd395f096fc89";
    ayxg = {
      url = "github:heartpunk/ayxg/607e482f4f6ff846cf213971ab958f466df901b2";
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
        };
      });
  };
}
