{
  description = "UTEM reborn: AYXG first Futamura projector contract";

  inputs = {
    ifrl.url = "github:heartpunk/ifrl/0eeb6ac73ee585ccdf746ba4f2c6e62291da930a";
    ayxg = {
      url = "github:heartpunk/ayxg/c7bd6ecc08a570c5b4a67643dcd33fc6c461bfec";
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
