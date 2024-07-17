{
  description = "Nix-on-Droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    nix-on-droid.url = "<<FLAKE_URL>>";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-on-droid, nixpkgs, ... }: {
    nixOnTermuxConfigurations = {
      default = nix-on-droid.lib.nixOnTermuxConfiguration {
        pkgs = import nixpkgs { system = "<<SYSTEM>>"; };
        modules = [ ./nix-on-droid.nix ];
      };
    };
  };
}
