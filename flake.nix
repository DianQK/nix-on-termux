{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/693bc46d169f5af9c992095736e82c3488bf7dbb";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nmd.follows = "nmd";
    };

    nmd = {
      url = "sourcehut:~rycee/nmd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-formatter-pack, nmd }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];

      overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);

      formatterPackArgsFor = forEachSystem (system: {
        inherit nixpkgs system;
        checkFiles = [ ./. ];

        config.tools = {
          deadnix = {
            enable = true;
            noLambdaPatternNames = true;
          };
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };
      });
    in
    {
      apps = forEachSystem (system: {
        default = self.apps.${system}.nix-on-droid;

        nix-on-droid = {
          type = "app";
          program = "${self.packages.${system}.nix-on-droid}/bin/nix-on-droid";
        };

        deploy = {
          type = "app";
          program = toString (import ./scripts/deploy.nix { inherit nixpkgs system; });
        };
      });

      checks = forEachSystem (system: {
        nix-formatter-pack-check = nix-formatter-pack.lib.mkCheck formatterPackArgsFor.${system};
      });

      formatter = forEachSystem (system: nix-formatter-pack.lib.mkFormatter formatterPackArgsFor.${system});

      lib.nixOnTermuxConfiguration =
        { pkgs
        , modules ? [ ]
        , extraSpecialArgs ? { }
        , home-manager-path ? home-manager.outPath
          # deprecated:
        , config ? null
        , extraModules ? null
        , system ? null  # pkgs.system is used to detect user's arch
        }:
        if ! (builtins.elem pkgs.system [ "aarch64-linux" "x86_64-linux" ]) then
          throw
            ("${pkgs.system} is not supported; aarch64-linux / x86_64-linux " +
              "are the only currently supported system types")
        else
          pkgs.lib.throwIf
            (config != null || extraModules != null || system != null)
            ''
              The 'nixOnTermuxConfiguration' arguments

              - 'config'
              - 'extraModules'
              - 'system'

              have been removed.
              Instead of 'extraModules' use the argument 'modules'.
              The 'system' will be inferred by 'pkgs.system',
              so pass a 'pkgs = import nixpkgs { system = "aarch64-linux"; };'
              See the 22.11 release notes for more.
            ''
            (import ./modules {
              targetSystem = pkgs.system; # system to cross-compile to
              inherit extraSpecialArgs home-manager-path pkgs;
              config.imports = modules;
              isFlake = true;
            });

      overlays.default = overlay;

      packages = forEachSystem (system:
        let
          customPkgs = (import ./pkgs {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
            }).customPkgs;

          docs = import ./docs {
            inherit home-manager;
            pkgs = nixpkgs.legacyPackages.${system};
            nmdSrc = nmd;
          };
        in
        {
          nix-on-droid = nixpkgs.legacyPackages.${system}.callPackage ./nix-on-droid { };
        }
        // customPkgs
        // docs
      );

      templates = {
        default = self.templates.minimal;

        minimal = {
          path = ./templates/minimal;
          description = "Minimal example of Nix-on-Droid system config.";
        };

        home-manager = {
          path = ./templates/home-manager;
          description = "Minimal example of Nix-on-Droid system config with home-manager.";
        };

        advanced = {
          path = ./templates/advanced;
          description = "Advanced example of Nix-on-Droid system config with home-manager.";
        };
      };
    };
}
