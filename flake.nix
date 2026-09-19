{
  description = "Home Manager module for managing MihomoManager proxy instances";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sub-nix.url = "github:yueyinqiu/SubNix";
    mihomo-manager-mihomo-mixin.url = "github:MihomoManager/MihomoManager.MihomoMixin-Nix";
  };

  outputs = {
    self,
    nixpkgs,
    sub-nix,
    mihomo-manager-mihomo-mixin,
  }: {
    homeManagerModules.default = { config, lib, pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      (import ./home-manager-modules/default.nix) {
        config = config;
        lib = lib;
        pkgs = pkgs;
        makeSubCli = sub-nix.lib.${system}.makeSubCli;
        sub = sub-nix.packages.${system}.sub;
        mihomo-manager-mihomo-mixin-package =
          mihomo-manager-mihomo-mixin.packages.${system}.default;
      };
  };
}
