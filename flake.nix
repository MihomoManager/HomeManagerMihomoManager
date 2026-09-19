{
  description = "Home Manager module for managing MihomoManager proxy instances";

  inputs = {
    sub-nix.url = "github:yueyinqiu/SubNix";
    mihomo-manager-mihomo-mixin.url = "github:MihomoManager/MihomoManager.MihomoMixin-Nix";
  };

  outputs =
    {
      self,
      sub-nix,
      mihomo-manager-mihomo-mixin,
    }:
    {
      homeManagerModules =
        let
          module =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            let
              system = pkgs.stdenv.hostPlatform.system;
            in
            (import ./home-manager-module) {
              config = config;
              lib = lib;
              pkgs = pkgs;
              makeSubCli = sub-nix.lib.${system}.makeSubCli;
              sub = sub-nix.packages.${system}.sub;
              mihomo-manager-mihomo-mixin-package = mihomo-manager-mihomo-mixin.packages.${system}.default;
            };
        in
        {
          default = module;
          home-manager-mihomo-manager = module;
        };
    };
}
