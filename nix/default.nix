{ pkgs }:
let
  manifest = (pkgs.lib.importTOML ../Cargo.toml).package;
in 
  pkgs.rustPlatform.buildRustPackage {
    pname = manifest.name;
    version = manifest.version;
    cargoLock.lockFile = ../Cargo.lock;
    src = pkgs.lib.cleanSource ../.;
    doCheck = false;
    meta = with pkgs.lib; {
      license = licenses.mit;
      maintainers = with maintainers; [ Abhinandh S ];
      platforms = platforms.linux;
      mainProgram = manifest.name;
    };
  }
