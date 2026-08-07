{ inputs, self, ... }:

let
  pname = "project-store";
in
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      checks = {
        ${pname} = pkgs.emacs.pkgs.${pname};
      };

      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
        config = { };
      };
    };

  flake.overlays.default = _final: prev: {
    emacsPackagesFor =
      emacs:
      (prev.emacsPackagesFor emacs).overrideScope (
        efinal: _eprev: {
          ${pname} = efinal.callPackage ./_package.nix { };
        }
      );
  };
}
