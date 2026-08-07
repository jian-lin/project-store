{
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:
    {
      apps.checkdoc = {
        type = "app";
        meta.description = "Run Emacs checkdoc-batch function against Emacs lisp files";
        program = self'.packages.checkdoc;
      };

      packages.checkdoc = pkgs.writeShellApplication {
        name = "checkdoc";
        runtimeInputs = [
          # checkdoc-batch is introduced in Emacs 31
          (lib.throwIfNot (lib.versionOlder pkgs.emacs.version "31")
            "checkdoc: replace pkgs.emacs31 with pkgs.emacs"
            pkgs.emacs31
          )
        ];
        text = ''
          for file in "$@"; do
            emacs --batch \
              --eval='(setq enable-local-variables :safe)' \
              --eval='(setq checkdoc-arguments-in-order-flag t)' \
              "$file" \
              --funcall=checkdoc-batch
          done
        '';
      };

      checks = { inherit (self'.packages) checkdoc; };
    };
}
