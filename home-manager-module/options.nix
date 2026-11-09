{
  lib,
  pkgs,
  sub,
  mihomo-manager-mihomo-mixin-package,
}:
{
  options.home-manager-mihomo-manager = {
    enable = lib.mkEnableOption "MihomoManager proxy instances";

    sub = lib.mkOption {
      type = lib.types.package;
      default = sub;
      description = ''
        The `sub` binary used to build the `home-manager-mihomo-manager` CLI.
      '';
    };

    mihomo = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.mihomo;
        description = ''
          The `mihomo` package used to run proxy instances.
        '';
      };

      install = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to add `mihomo.package` to `home.packages`.
        '';
      };
    };

    mihomo-manager-mihomo-mixin = {
      package = lib.mkOption {
        type = lib.types.package;
        default = mihomo-manager-mihomo-mixin-package;
        description = ''
          The MihomoManager.MihomoMixin package used to merge proxy
          configuration at service startup.
        '';
      };

      install = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to add `mihomo-manager-mihomo-mixin.package` to
          `home.packages`.
        '';
      };
    };

    mihomo-tui = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.mihomo-tui;
        description = ''
          The mihomo-tui package used by the `tui` action.
        '';
      };

      install = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to add `mihomo-tui.package` to `home.packages`.
        '';
      };
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "Mixed port of the proxy instance.";
            };

            configuration = lib.mkOption {
              type = lib.types.path;
              description = ''
                Directory copied into the instance's config directory
                (`~/.config/home-manager-mihomo-manager/<name>`). Typically
                contains the generation script and its input files (JS
                mixin scripts, YAML fragments).
              '';
            };

            entry = lib.mkOption {
              type = lib.types.str;
              default = "config.sh";
              description = ''
                Name of the generation script inside the configuration
                directory, run at service startup.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Proxy instances. Each instance gets a `home-manager-mihomo-manager-<name>`
        systemd user service and an entry in the `home-manager-mihomo-manager` CLI.
      '';
    };
  };
}