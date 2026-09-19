# HomeManagerMihomoManager

Home Manager module for managing [Mihomo](https://github.com/MihomoParty/mihomo) proxy instances.

Each declared instance gets:

- a `home-manager-mihomo-manager-<name>` systemd user service running Mihomo with a
  config merged by [MihomoManager.MihomoMixin](https://github.com/MihomoManager/MihomoManager.MihomoMixin);
- a `home-manager-mihomo-manager` CLI (built on [sub](https://github.com/juanibiapina/sub)) with
  `restart`, `log`, `tui`, `with`, and `show` actions, plus dynamic bash completion.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager-mihomo-manager.url = "github:yueyinqiu/HomeManagerMihomoManager";
  };

  outputs = { nixpkgs, home-manager, home-manager-mihomo-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          home-manager-mihomo-manager.homeManagerModules.home-manager-mihomo-manager
          {
            home.username = "alice";
            home.homeDirectory = "/home/alice";
            home.stateVersion = "26.05";

            programs.home-manager-mihomo-manager = {
              enable = true;
              instances.example = {
                port = 42931;
                configuration = ./config;
              };
            };
          }
        ];
      };
    };
}
```

## Options

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Whether to enable the module |
| `sub` | package | `SubNix` flake's `sub` | `sub` binary used to build the CLI |
| `mihomo-manager-mihomo-mixin` | package | `MihomoManager.MihomoMixin-Nix` flake | Config merge tool |
| `mihomo-tui` | package | built-in `mihomo-tui` | TUI used by the `tui` action |
| `instances` | attrsOf submodule | `{ }` | Proxy instances to manage |

Each `instances.<name>` accepts:

| Name | Type | Description |
| --- | --- | --- |
| `port` | port | Mixed port of the instance |
| `configuration` | path | Directory copied into `~/.config/home-manager-mihomo-manager/<name>` |
| `entry` | str | Generation script inside `configuration`, defaults to `config.sh` |

## Configuration

Each instance's `configuration` directory is copied to
`~/.config/home-manager-mihomo-manager/<name>`. At service startup, the
`entry` script (default `config.sh`) is run from that directory (with the
instance's own files as the working directory) to generate the Mihomo
configuration.

The entry script is invoked as `bash <entry>` and receives these
environment variables:

| Name | Description |
| --- | --- |
| `MMMM` | The `MihomoManager.MihomoMixin` binary |
| `OUTPUT_PATH` | Where to write the generated configuration |
| `TEMP_DIRECTORY` | Temporary files, cleaned up after the service stops |
| `STATE_DIRECTORY` | Persistent files, retained across runs |
| `HOME_MANAGER_MIHOMO_MANAGER_PROXIES` | Generated YAML listing all managed instances as socks5 proxies |

A minimal `config.sh`:

```sh
#!/usr/bin/env bash

# "$MMMM" for the MihomoManager.MihomoMixin binary
# "$OUTPUT_PATH" for writing the final merged configuration
# "$TEMP_DIRECTORY" for temporary files
# "$STATE_DIRECTORY" for persistent files
# "$HOME_MANAGER_MIHOMO_MANAGER_PROXIES" for the generated list of managed proxy instances
# . for the instance's own configuration files

origin="$STATE_DIRECTORY/origin.yaml"
if [ -z "$(find "$origin" -mtime -30)" ]; then
    curl -L -H "User-Agent: flclash" --output "$origin" https://example.com/subscription
fi

"$MMMM" \
    merge "$origin" \
    merge "$HOME_MANAGER_MIHOMO_MANAGER_PROXIES" \
    js to-global.js \
    save "$OUTPUT_PATH"
```

## CLI

```
home-manager-mihomo-manager restart <name>         systemctl --user restart home-manager-mihomo-manager-<name>
home-manager-mihomo-manager log <name>             journalctl --user -uf home-manager-mihomo-manager-<name>
home-manager-mihomo-manager tui <name>             mihomo-tui -c <state>/home-manager-mihomo-manager/state/<name>/tui/config.yaml
home-manager-mihomo-manager with <name> <cmd...>   run <cmd...> with proxy env vars set
home-manager-mihomo-manager show <name>            print port, config dir, and state dir
```

---

All documentation and `description` fields in this repository are AI-generated.
