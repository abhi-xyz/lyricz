{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    unstable-nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };


  outputs = { self, nixpkgs, unstable-nixpkgs }: let
    system = "x86_64-linux";
    manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          unstable = import unstable-nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        })
      ];
    };
  in {

    formatter.${system} = pkgs.alejandra;
    packages.${system} = {
      ${manifest.name} = pkgs.callPackage ./nix/default.nix { inherit pkgs; };
      default = self.packages.${system}.${manifest.name};
    };
    devShells.${system}.default = import ./nix/shell.nix { inherit pkgs; };
  };
}
