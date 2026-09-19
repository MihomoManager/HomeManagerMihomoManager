{
  config,
  lib,
  pkgs,
  makeSubCli,
}:

let
  cfg = config.programs.home-manager-mihomo-manager;

  proxiesList = pkgs.writeText "home-manager-mihomo-manager-proxies.yaml" (
    builtins.toJSON {
      proxies = lib.mapAttrsToList (n: it: {
        name = "home-manager-mihomo-manager-${n}";
        type = "socks5";
        server = "127.0.0.1";
        port = it.port;
      }) cfg.instances;
    }
  );
in
{
  home.packages = [
    pkgs.mihomo
    (import ./cli.nix {
      config = config;
      lib = lib;
      pkgs = pkgs;
      makeSubCli = makeSubCli;
      cfg = cfg;
    })
    cfg.mihomo-manager-mihomo-mixin
    cfg.mihomo-tui
  ];

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
          cd "${config.xdg.configHome}/home-manager-mihomo-manager/${name}"
          mkdir -p "/tmp/entry"
          mkdir -p "$STATE_DIRECTORY/entry"
          HOME_MANAGER_MIHOMO_MANAGER_PROXIES="${proxiesList}" \
            MMMM="${cfg.mihomo-manager-mihomo-mixin}/bin/MihomoManager.MihomoMixin" \
            OUTPUT_PATH="/tmp/merged.yaml" \
            TEMP_DIRECTORY="/tmp/entry" \
            STATE_DIRECTORY="$STATE_DIRECTORY/entry" \
            bash ${item.entry}

          mkdir -p "$STATE_DIRECTORY/core"
          "${cfg.mihomo-manager-mihomo-mixin}/bin/MihomoManager.MihomoMixin" merge /tmp/merged.yaml merge "${portYaml}" save "$STATE_DIRECTORY/core/config.yaml"

          SOCKET="$RUNTIME_DIRECTORY/mihomo.sock"

          mkdir -p "$STATE_DIRECTORY/tui"
          printf 'mihomo-api: unix:%s\n' "$SOCKET" > "$STATE_DIRECTORY/tui/config.yaml"

          cd "$STATE_DIRECTORY/core"
          SAFE_PATHS="$STATE_DIRECTORY" exec "${pkgs.mihomo}/bin/mihomo" -d . -ext-ctl-unix "$SOCKET"
        '';
      };
    in
    lib.nameValuePair "home-manager-mihomo-manager-${name}" {
      Unit = {
        Description = "home-manager-mihomo-manager Service ${name}";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        X-Restart-Triggers = [ (toString item.configuration) ];
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
