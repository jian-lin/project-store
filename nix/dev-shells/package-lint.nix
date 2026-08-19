# SPDX-FileCopyrightText: 2026 Lin Jian <me@linj.tech>
# SPDX-License-Identifier: GPL-3.0-or-later

{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      apps.package-lint = {
        type = "app";
        meta.description = "Run package-lint-batch-and-exit against Emacs lisp files";
        program = self'.checks.package-lint;
      };

      checks.package-lint = pkgs.writeShellApplication {
        name = "package-lint";
        runtimeInputs = [
          (pkgs.emacs.pkgs.withPackages (epkgs: [ epkgs.package-lint ]))
        ];
        text = ''
          emacs --batch --load=package-lint --funcall=package-lint-batch-and-exit "$@"
        '';
      };
    };
}
