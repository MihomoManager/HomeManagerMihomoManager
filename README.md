# HomeManagerMihomoManager

Home Manager module for managing [Mihomo](https://github.com/MihomoParty/mihomo) proxy instances.

Each declared instance gets:

- a `home-manager-mihomo-manager-<name>` systemd user service running Mihomo with a
  config merged by [MihomoManager.MihomoMixin](https://github.com/MihomoManager/MihomoManager.MihomoMixin);
- a `home-manager-mihomo-manager` CLI (built on [sub](https://github.com/juanibiapina/sub)) with
  `restart`, `log`, `tui`, `with`, and `show` actions, plus dynamic bash completion.

## Adding as a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mihomo-manager.url = "github:yueyinqiu/HomeManagerMihomoManager";
  };

  outputs = { nixpkgs, mihomo-manager, ... }: {
    homeConfigurations.alice = ...;
  };
}
```

## Usage

```nix
{
  imports = [ mihomo-manager.homeManagerModules.default ];

  programs.home-manager-mihomo-manager = {
    enable = true;

    instances.example = {
      port = 42931;
      configuration = ./config;
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
