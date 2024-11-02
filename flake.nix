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
      homeManagerModules.${manifest.name} = { config, pkgs, lib, ... }:
        let
          tomlFormat = pkgs.formats.toml { };
        in
          {
          options.program.${manifest.name} = {
            enable = lib.mkEnableOption "Enable the ${manifest.name} program";

            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.callPackage ./nix/default.nix { };
              description = "The ${manifest.name} package to use.";
            };
            settings = lib.mkOption {
              type = tomlFormat.type;
              default = { };
              example = lib.literalExpression ''
                [directories]
                images_path = "/home/abhi/pics/pictures/images"

                [input]
                dirs = [
                  "/home/abhi/videos",
                ]
              '';
              description = ''
                Configuration written to {file}`$XDG_CONFIG_HOME/${manifest.name}/config.toml`.
              '';
            };
          };
          config = lib.mkIf config.program.${manifest.name}.enable {
            home.packages = [ config.program.${manifest.name}.package ];

            xdg.configFile."${manifest.name}/config.toml" = lib.mkIf (config.program.${manifest.name}.settings != { }) {
              source = tomlFormat.generate "config.toml" config.program.${manifest.name}.settings;
            };
          };
        };
      homeManagerModules.default = self.homeManagerModules.${manifest.name};
      devShells.${system}.default = pkgs.callPackage ./nix/shell.nix {};
    };
}
