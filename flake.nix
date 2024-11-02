{
  description = "Rust flake templalte";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };
  outputs = {
    self,
    nixpkgs,
    }: let
      system = "x86_64-linux";
      manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        ${manifest.name} = pkgs.callPackage ./nix/default.nix { };
        default = self.packages.${system}.${manifest.name};
      };
      formatter.${system} = pkgs.alejandra;
      homeManagerModules.${manifest.name} = import ./nix/home-module.nix;
      homeManagerModules.default = self.homeManagerModules.${manifest.name};
      devShells.${system}.default = pkgs.callPackage ./nix/shell.nix {};
    };
}
