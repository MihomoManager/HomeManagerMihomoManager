{
  config,
  lib,
  pkgs,
  makeSubCli,
  cfg
}:

let
  commands = name: {
    restart = ''
      #!/usr/bin/env bash
      systemctl --user restart ${lib.escapeShellArg "home-manager-mihomo-manager-${name}"}
    '';

    log = ''
      #!/usr/bin/env bash
      journalctl --user -u ${lib.escapeShellArg "home-manager-mihomo-manager-${name}"}
    '';

    tui = ''
      #!/usr/bin/env bash
      exec "${cfg.mihomo-tui}/bin/mihomo-tui" -c ${lib.escapeShellArg "${config.xdg.stateHome}/home-manager-mihomo-manager/state/${name}/tui/config.yaml"}
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
      printf "Service: %s\n" ${lib.escapeShellArg "home-manager-mihomo-manager-${name}"}
      printf "Configuration Directory: %s\n" ${lib.escapeShellArg "${config.xdg.configHome}/home-manager-mihomo-manager/${name}"}
      printf "State Directory: %s\n" ${lib.escapeShellArg "${config.xdg.stateHome}/home-manager-mihomo-manager/state/${name}"}
    '';
  };
in
makeSubCli {
  pname = "home-manager-mihomo-manager";
  version = "";
  sub = cfg.sub;
  src = pkgs.runCommand "home-manager-mihomo-manager-cli" { } (
    lib.concatMapStringsSep "\n" (
      name:
      lib.concatMapAttrsStringSep "\n" (action: text: ''
        dir="$out/libexec/${action}"
        file="$dir/"${lib.escapeShellArg name}
        mkdir -p "$dir"
        cat > "$file" <<'EOF'
        ${text}
        EOF
        chmod +x "$file"
      '') (commands name)
    ) (builtins.attrNames cfg.instances)
  );
}
