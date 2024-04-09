{
  description = "Link Shortener";

  inputs = {
    beam-flakes = {
      url = "github:shanesveller/nix-beam-flakes";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    pre-commit.url = "github:hercules-ci/pre-commit-hooks.nix/flakeModule";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    beam-flakes,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [beam-flakes.flakeModule];

      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = _: {
        beamWorkspace = {
          enable = true;
          devShell = {
            languageServers.elixir = true;
            languageServers.erlang = false;
            phoenix = true;
          };
          versions = {
            elixir = "1.16.2";
            erlang = "26.2.3";
          };
        };
      };
    };
}
