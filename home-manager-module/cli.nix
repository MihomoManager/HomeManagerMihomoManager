{
  config,
  lib,
  pkgs,
  makeSubCli,
  cfg
}:

let
  actions = {
    restart = name: ''
      #!/usr/bin/env bash
      systemctl --user restart ${lib.escapeShellArg "home-manager-mihomo-manager-${name}"}
    '';

    log = name: ''
      #!/usr/bin/env bash
      journalctl --user -u ${lib.escapeShellArg "home-manager-mihomo-manager-${name}"}
    '';

    tui = name: ''
      #!/usr/bin/env bash
      exec "${cfg.mihomo-tui}/bin/mihomo-tui" -c ${lib.escapeShellArg "${config.xdg.stateHome}/home-manager-mihomo-manager/state/${name}/tui/config.yaml"}
    '';

    "with" = name: ''
      #!/usr/bin/env bash
      export ALL_PROXY="http://127.0.0.1:${toString cfg.instances.${name}.port}"
      export HTTP_PROXY="$ALL_PROXY"
      export HTTPS_PROXY="$ALL_PROXY"
      export all_proxy="$ALL_PROXY"
      export http_proxy="$ALL_PROXY"
      export https_proxy="$ALL_PROXY"
      exec "$@"
    '';

    show = name: ''
      #!/usr/bin/env bash
      printf "Port: %s\n" "${toString cfg.instances.${name}.port}"
      printf "Service: %s\n" ${lib.escapeShellArg "home-manager-mihomo-manager-${name}"}
      printf "Configuration Directory: %s\n" ${lib.escapeShellArg "${config.xdg.configHome}/home-manager-mihomo-manager/${name}"}
      printf "State Directory: %s\n" ${lib.escapeShellArg "${config.xdg.stateHome}/home-manager-mihomo-manager/state/${name}"}
    '';
  };

  list = ''
    #!/usr/bin/env bash
    ${lib.concatMapStringsSep "\n" (name: ''
      printf "%s\n" ${lib.escapeShellArg name}
    '') (builtins.attrNames cfg.instances)}
  '';
in
makeSubCli {
  pname = "home-manager-mihomo-manager";
  version = "";
  sub = cfg.sub;
  src = pkgs.runCommand "home-manager-mihomo-manager-cli" { } (
    ''
      mkdir -p "$out/libexec"
      ${lib.concatMapStringsSep "\n" (action: ''
        mkdir -p "$out/libexec/${action}"
      '') (builtins.attrNames actions)}

      cat > "$out/libexec/list" <<'EOF'
      ${list}
      EOF
      chmod +x "$out/libexec/list"
    ''
    + (lib.concatMapStringsSep "\n" (
      name:
      lib.concatMapAttrsStringSep "\n" (action: script: ''
        dir="$out/libexec/${action}"
        file="$dir/"${lib.escapeShellArg name}
        mkdir -p "$dir"
        cat > "$file" <<'EOF'
        ${script name}
        EOF
        chmod +x "$file"
      '') actions
    ) (builtins.attrNames cfg.instances))
  );
}
