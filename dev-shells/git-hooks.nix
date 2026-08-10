# SPDX-FileCopyrightText: 2026 Lin Jian <me@linj.tech>
# SPDX-License-Identifier: GPL-3.0-or-later

{ inputs, ... }:

{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    {
      self',
      ...
    }:
    {
      pre-commit = {
        settings.hooks = {
          # keep-sorted start block=yes
          actionlint.enable = true;
          checkLocalLinks = {
            enable = true;
            name = "Check local links";
            entry = self'.apps.checkLinks.program;
            args = [
              "--no-progress"
              "--offline"
            ];
            types = [ "text" ];
            language = "unsupported";
          };
          checkdoc = {
            enable = true;
            name = "checkdoc";
            entry = self'.apps.checkdoc.program;
            files = "\\.el$";
            types = [ "text" ];
            language = "unsupported";
          };
          packageLint = {
            enable = true;
            name = "package-lint";
            entry = self'.apps.packageLint.program;
            files = "\\.el$";
            types = [ "text" ];
            language = "unsupported";
          };
          reuse.enable = true;
          treefmt.enable = true;
          zizmor = {
            enable = true;
            entry = self'.apps.zizmor.program;
            args = [
              "--no-progress"
            ];
            files = "^\\.github/(dependabot\\.|actions/|workflows/)";
          };
          # keep-sorted end
        };
      };
    };
}
