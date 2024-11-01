{
  description = "Rust flake templalte";

  inputs = {
    # unstable-nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };

  outputs = { self, nixpkgs } @ inputs:
    let
      system = "x86_64-linux";
      manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
      pkgs = nixpkgs.legacyPackages.${system};
      # upkgs = unstable-nixpkgs.legacyPackages.${system};
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
      # Executed by `nix run .#<name>`
      apps.${system}.${manifest.name} = {
        type = "app";
        program = self.packages.${system}.${manifest.name}/bin/${manifest.name};
      };
      # # Executed by `nix run . -- <args?>`
      apps.${system}.default = {
        type = "app";
        program = self.packages.${system}.${manifest.name}/bin/${manifest.name};
      };

      # Formatter (alejandra, nixfmt or nixpkgs-fmt)
      formatter.${system} = pkgs.alejandra;
      # Overlay, consumed by other flakes
      overlays.${manifest.name} = final: prev: {
        customPkg = pkgs.callPackage ./nix/default.nix { };
        # Override the Rust compiler version
        rustc = final.rust-bin.stable."1.70.0";
      };
      # Default overlay
      overlays.default = final: prev: {
        defaultPkg = pkgs.callPackage ./nix/default.nix {};
      };

      homeManagerModules.${manifest.name} = pkgs.callPackage ./nix/home-module.nix;
      homeManagerModules.default = self.homeManagerModules.${manifest.name};

      # Nixos module, consumed by other flakes
      nixosModules.${manifest.name} = { config, ... }: { options = {}; config = {}; };
      # Default module
      nixosModules.default = { config, ... }: { options = {}; config = {}; };

      devShells.${system}.default = pkgs.callPackage ./nix/shell.nix { };      
    };
}
