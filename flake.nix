{
  description = "UTEM reborn: AYXG first Futamura projector contract";

  inputs = {
    ifrl.url = "github:heartpunk/ifrl/57edc5144c506bd5a13028738e6df057528f402c";
    ayxg = {
      url = "github:heartpunk/ayxg/ab2bee80d559b864ca512058b75db75e2052d357";
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
