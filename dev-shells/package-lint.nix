{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      apps.packageLint = {
        type = "app";
        meta.description = "Run package-lint-batch-and-exit against Emacs lisp files";
        program = self'.packages.packageLint;
      };

      packages.packageLint = pkgs.writeShellApplication {
        name = "package-lint";
        runtimeInputs = [
          (pkgs.emacs.pkgs.withPackages (epkgs: [ epkgs.package-lint ]))
        ];
        text = ''
          emacs --batch --load=package-lint --funcall=package-lint-batch-and-exit "$@"
        '';
      };

      checks = { inherit (self'.packages) packageLint; };
    };
}
