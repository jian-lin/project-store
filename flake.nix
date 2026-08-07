{
  description = "Emacs project backend for Nix store";

  inputs = {
    # keep-sorted start block=yes
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # keep-sorted end
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports =
          let
            filter = lib.fileset.fileFilter (file: isNix file && !isSpecialNix file && !isIgnored file);
            isNix = file: file.hasExt "nix";
            isSpecialNix =
              file:
              lib.elem file.name [
                "flake.nix"
                "default.nix"
              ];
            isIgnored = file: lib.hasPrefix "_" file.name;
          in
          lib.fileset.toList (filter ./.);

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
      }
    );
}
