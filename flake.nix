{
  description = "Rust flake templalte";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
      pkgs = nixpkgs.legacyPackages.${system};
    in {

      # Executed by `nix flake check`
      checks.${system}.${manifest.name} = pkgs.callPackage ./nix/default.nix {
        # Force `doCheck` to true, overriding default setting
        doCheck = pkgs.lib.mkForce true;
      };
      # Executed by `nix build .#<name>`
      packages.${system} = {
      ${manifest.name} = pkgs.callPackage ./nix/default.nix;
      # Executed by `nix build .`
      default = pkgs.callPackage ./nix/default.nix;
      };

      # Formatter (alejandra, nixfmt or nixpkgs-fmt)
      formatter.${system} = pkgs.alejandra;

      homeManagerModules.${manifest.name} = pkgs.callPackage ./nix/home-module.nix;
      homeManagerModules.default = self.homeManagerModules.${manifest.name};

      devShells.${system}.default = pkgs.callPackage ./nix/shell.nix { };      
    };
}
