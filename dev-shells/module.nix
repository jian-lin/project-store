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
