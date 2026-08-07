{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      apps.zizmor = {
        type = "app";
        meta.description = "Pre-configured zizmor";
        program = self'.packages.zizmor;
      };

      packages.zizmor =
        let
          args = [
            "--strict-collection"
            "--persona=auditor"
            "--no-config"
            "--show-audit-urls=always"
          ];
        in
        pkgs.writeShellApplication {
          name = "zizmor-with-config";
          runtimeInputs = [ pkgs.zizmor ];
          text = ''
            zizmor ${lib.escapeShellArgs args} "$@"
          '';
        };

      checks = { inherit (self'.packages) zizmor; };
    };
}
