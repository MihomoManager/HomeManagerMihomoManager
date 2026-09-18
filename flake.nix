{
  description = "Home Manager module for managing MihomoManager proxy instances";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sub-nix.url = "github:yueyinqiu/SubNix";
    sub-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    sub-nix,
  }: {
    homeManagerModules.default = {
      imports = [
        sub-nix.homeManagerModules.sub-nix
        ./home-manager-modules/default.nix
      ];
    };
  };
}
