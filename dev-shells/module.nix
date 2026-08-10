# SPDX-FileCopyrightText: 2026 Lin Jian <me@linj.tech>
# SPDX-License-Identifier: GPL-3.0-or-later

{
  perSystem = { config, pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      inputsFrom = [
        config.pre-commit.devShell
        config.treefmt.build.devShell
      ];
      package = [
        pkgs.nil
      ];
    };
  };
}
