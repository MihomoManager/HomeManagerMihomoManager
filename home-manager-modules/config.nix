{
  config,
  lib,
  pkgs,
  cli,
}:

let
  cfg = config.programs.home-manager-mihomo-manager;
in
{
  home.packages = [
    pkgs.mihomo
    cli
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
}
