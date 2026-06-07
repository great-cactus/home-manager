{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, claude-code, ... }:
    let
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ claude-code.overlays.default ];
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "claude-code"
          "copilot-language-server"
          "corefonts"
        ];
      };
      username = builtins.getEnv "USER";
    in
    assert username != "" || builtins.throw "USER environment variable is not set. Run with --impure flag.";
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.home-manager ];
        };
      }
    ) // {
      homeConfigurations = {
        "linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit username;
            homeDirectory = "/home/${username}";
          };
        };
        "macos" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "aarch64-darwin";
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit username;
            homeDirectory = "/Users/${username}";
          };
        };
        "hpc" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          modules = [ ./home-hpc.nix ];
          extraSpecialArgs = {
            inherit username;
            homeDirectory = "/home/${username}";
          };
        };
      };
    };
}
