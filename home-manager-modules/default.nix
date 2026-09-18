{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.home-manager-mihomo-manager;

  commands = name: {
    restart = ''
      #!/usr/bin/env bash
      systemctl --user restart "home-manager-mihomo-manager-${name}"
    '';

    log = ''
      #!/usr/bin/env bash
      journalctl --user -uf "home-manager-mihomo-manager-${name}"
    '';

    tui = ''
      #!/usr/bin/env bash
      exec ${cfg.mihomo-tui}/bin/mihomo-tui -c "${config.xdg.stateHome}/home-manager-mihomo-manager/state/${name}/tui/config.yaml"
    '';

    "with" = ''
      #!/usr/bin/env bash
      export ALL_PROXY="http://127.0.0.1:${toString cfg.instances.${name}.port}"
      export HTTP_PROXY="$ALL_PROXY"
      export HTTPS_PROXY="$ALL_PROXY"
      export all_proxy="$ALL_PROXY"
      export http_proxy="$ALL_PROXY"
      export https_proxy="$ALL_PROXY"
      exec "$@"
    '';

    show = ''
      #!/usr/bin/env bash
      printf "Port: %s\n" "${toString cfg.instances.${name}.port}"
      printf "Configuration Directory: %s\n" "${config.xdg.configHome}/home-manager-mihomo-manager/${name}"
      printf "State Directory: %s\n" "${config.xdg.stateHome}/home-manager-mihomo-manager/state/${name}"
    '';
  };
in
{
  options.programs.home-manager-mihomo-manager = {
    enable = lib.mkEnableOption "MihomoManager proxy instances";

    mihomo-manager-mihomo-mixin = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../packages/mihomo-manager-mihomo-mixin { };
      description = ''
        The MihomoManager.MihomoMixin package used to merge proxy
        configuration at service startup.
      '';
    };

    mihomo-tui = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../packages/mihomo-tui.nix { };
      description = ''
        The mihomo-tui package used by the `tui` action.
      '';
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "Mixed port of the proxy instance.";
            };

            files = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              description = ''
                Configuration files copied into the instance's config
                directory (e.g. `config.sh.example`, JS mixin scripts, YAML
                fragments).
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

  config = lib.mkIf cfg.enable {
    programs."sub-nix" = {
      enable = true;
      clis.home-manager-mihomo-manager = {
        version = "0.1.0";
        scripts = pkgs.runCommand "home-manager-mihomo-manager-sub" { } (
          lib.concatMapStringsSep "\n" (
            name:
            lib.concatMapAttrsStringSep "\n" (action: text: ''
              mkdir -p "$out/libexec/${action}"
              cat > "$out/libexec/${action}/${name}" <<'EOF'
              ${text}
              EOF
              chmod +x "$out/libexec/${action}/${name}"
            '') (commands name)
          ) (builtins.attrNames cfg.instances)
        );
      };
    };

    home.packages = [
      pkgs.mihomo
      cfg.mihomo-manager-mihomo-mixin
      cfg.mihomo-tui
    ];

    xdg.configFile = lib.mergeAttrsList (
      lib.mapAttrsToList (
        name: item:
        builtins.listToAttrs (
          map (file: {
            name = "home-manager-mihomo-manager/${name}/${baseNameOf file}";
            value = {
              source = file;
            };
          }) item.files
          ++ [
            {
              name = "home-manager-mihomo-manager/${name}/home-manager-mihomo-manager.yaml";
              value = {
                text = builtins.toJSON {
                  proxies = lib.mapAttrsToList (n: it: {
                    name = "home-manager-mihomo-manager-${n}";
                    type = "socks5";
                    server = "127.0.0.1";
                    port = it.port;
                  }) cfg.instances;
                };
              };
            }
            {
              name = "home-manager-mihomo-manager/${name}/restart.sh";
              value = {
                text = ''
                  systemctl --user restart "home-manager-mihomo-manager-${name}.service"
                '';
              };
            }
          ]
        )
      ) cfg.instances
    );

    systemd.user.services = lib.mapAttrs' (
      name: item:
      let
        portYaml = pkgs.writeText "home-manager-mihomo-manager-${name}-port.yaml" ''
          mixed-port: ${toString item.port}
        '';

        runner = pkgs.writeShellScript "home-manager-mihomo-manager-${name}-run" ''
          set -e

          cd "${config.xdg.configHome}/home-manager-mihomo-manager/${name}"
          mkdir -p "/tmp/config-sh"
          mkdir -p "$STATE_DIRECTORY/config-sh"
          MMMM="${cfg.mihomo-manager-mihomo-mixin}/bin/MihomoManager.MihomoMixin" \
            OUTPUT_PATH="/tmp/merged.yaml" \
            TEMP_DIRECTORY="/tmp/config-sh" \
            STATE_DIRECTORY="$STATE_DIRECTORY/config-sh" \
            bash config.sh

          mkdir -p "$STATE_DIRECTORY/core"
          "${cfg.mihomo-manager-mihomo-mixin}/bin/MihomoManager.MihomoMixin" merge /tmp/merged.yaml merge "${portYaml}" save "$STATE_DIRECTORY/core/config.yaml"

          SOCKET="$RUNTIME_DIRECTORY/mihomo.sock"

          mkdir -p "$STATE_DIRECTORY/tui"
          printf 'mihomo-api: unix:%s\n' "$SOCKET" > "$STATE_DIRECTORY/tui/config.yaml"

          cd "$STATE_DIRECTORY/core"
          SAFE_PATHS="$STATE_DIRECTORY" exec "${pkgs.mihomo}/bin/mihomo" -d . -ext-ctl-unix "$SOCKET"
        '';
      in
      lib.nameValuePair "home-manager-mihomo-manager-${name}" {
        Unit = {
          Description = "home-manager-mihomo-manager Service ${name}";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${runner}";
          Restart = "on-failure";
          RestartSec = "5s";
          PrivateTmp = true;
          StateDirectory = "home-manager-mihomo-manager/state/${name}";
          RuntimeDirectory = "home-manager-mihomo-manager-${name}";
        };
      }
    ) cfg.instances;
  };
}
