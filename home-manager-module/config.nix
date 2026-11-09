{
  config,
  lib,
  pkgs,
  makeSubCli,
}:

let
  cfg = config.home-manager-mihomo-manager;

  proxiesList = pkgs.writeText "home-manager-mihomo-manager-proxies.yaml" (
    builtins.toJSON {
      proxies = lib.mapAttrsToList (n: it: {
        name = "hmmm-${n}";
        type = "socks5";
        server = "127.0.0.1";
        port = it.port;
        udp = true;
      }) cfg.instances;
    }
  );
in
{
  home.packages =
    [
      (import ./cli.nix {
        config = config;
        lib = lib;
        pkgs = pkgs;
        makeSubCli = makeSubCli;
        cfg = cfg;
      })
    ]
    ++ lib.optionals cfg.mihomo.install [ cfg.mihomo.package ]
    ++ lib.optionals cfg.mihomo-manager-mihomo-mixin.install [ cfg.mihomo-manager-mihomo-mixin.package ]
    ++ lib.optionals cfg.mihomo-tui.install [ cfg.mihomo-tui.package ];

  xdg.configFile = lib.mapAttrs' (
    name: item:
    lib.nameValuePair "home-manager-mihomo-manager/${name}" {
      source = item.configuration;
      recursive = true;
    }
  ) cfg.instances;

  systemd.user.services = lib.mapAttrs' (
    name: item:
    let
      portYaml = pkgs.writeText "home-manager-mihomo-manager-${name}-port.yaml" ''
        mixed-port: ${toString item.port}
      '';

      runner = pkgs.writeShellApplication {
        name = "home-manager-mihomo-manager-${name}-run";
        text = ''
          cd ${lib.escapeShellArg "${config.xdg.configHome}/home-manager-mihomo-manager/${name}"}
          mkdir -p "/tmp/entry"
          mkdir -p "$STATE_DIRECTORY/entry"
          HOME_MANAGER_MIHOMO_MANAGER_PROXIES="${proxiesList}" \
            MMMM="${cfg.mihomo-manager-mihomo-mixin.package}/bin/MihomoManager.MihomoMixin" \
            OUTPUT_PATH="/tmp/merged.yaml" \
            TEMP_DIRECTORY="/tmp/entry" \
            STATE_DIRECTORY="$STATE_DIRECTORY/entry" \
            bash ${lib.escapeShellArg item.entry}

          mkdir -p "$STATE_DIRECTORY/core"
          "${cfg.mihomo-manager-mihomo-mixin.package}/bin/MihomoManager.MihomoMixin" merge /tmp/merged.yaml merge "${portYaml}" save "$STATE_DIRECTORY/core/config.yaml"

          SOCKET="$RUNTIME_DIRECTORY/mihomo.sock"

          mkdir -p "$STATE_DIRECTORY/tui"
          printf 'mihomo-api: unix:%s\n' "$SOCKET" > "$STATE_DIRECTORY/tui/config.yaml"

          cd "$STATE_DIRECTORY/core"
          SAFE_PATHS="$STATE_DIRECTORY" exec "${cfg.mihomo.package}/bin/mihomo" -d . -ext-ctl-unix "$SOCKET"
        '';
      };
    in
    lib.nameValuePair "home-manager-mihomo-manager-${name}" {
      Unit = {
        Description = "home-manager-mihomo-manager Service ${name}";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        X-Restart-Triggers = [ "${item.configuration}" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = "${runner}/bin/home-manager-mihomo-manager-${name}-run";
        Restart = "on-failure";
        RestartSec = "5s";
        PrivateTmp = true;
        StateDirectory = "home-manager-mihomo-manager/state/${name}";
        RuntimeDirectory = "home-manager-mihomo-manager-${name}";
      };
    }
  ) cfg.instances;
}
