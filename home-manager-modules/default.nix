{
  config,
  lib,
  pkgs,
  makeSubCli,
  sub,
  mihomo-manager-mihomo-mixin-package,
  ...
}:
{
  imports = [
    (import ./options.nix {
      lib = lib;
      pkgs = pkgs;
      sub = sub;
      mihomo-manager-mihomo-mixin-package = mihomo-manager-mihomo-mixin-package;
    })
  ];

  config = lib.mkIf config.programs.home-manager-mihomo-manager.enable (
    import ./config.nix {
      config = config;
      lib = lib;
      pkgs = pkgs;
      cli = import ./cli.nix {
        config = config;
        lib = lib;
        pkgs = pkgs;
        makeSubCli = makeSubCli;
        commdns = (import ./commands.nix { inherit config; });
      };
    }
  );
}
