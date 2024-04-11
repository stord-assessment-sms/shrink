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
    pre-commit,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [beam-flakes.flakeModule pre-commit.flakeModule];

      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        beamWorkspace = {
          enable = true;
          devShell = {
            extraArgs.shellHook = config.pre-commit.installationScript;
            extraPackages = [pkgs.flyctl];
            languageServers.elixir = true;
            languageServers.erlang = false;
            phoenix = true;
          };
          versions = {
            elixir = "1.16.2";
            erlang = "26.2.3";
          };
        };

        pre-commit = {
          settings = {
            hooks = {
              alejandra.enable = true;

              credo = {
                enable = true;
                name = "credo";
                entry = "mix credo suggest --all --format=oneline --strict";
                files = "\\.(ex|exs|heex)$";
                language = "system";
              };

              mix-compile = {
                enable = true;
                name = "mix compile warnings";
                entry = "mix compile --all-warnings --warnings-as-errors";
                files = "\\.(ex|exs|heex)$";
                language = "system";
                pass_filenames = false;
              };

              mix-format = {
                enable = true;
                name = "mix format";
                entry = "mix format --check-formatted";
                files = "\\.(exs?|heex)$";
                language = "system";
              };

              mix-test = {
                enable = true;
                name = "mix test";
                entry = "mix test";
                files = "\\.(exs?|heex)$";
                language = "system";
                pass_filenames = false;
              };

              prettier.enable = true;
              prettier.excludes = ["flake.lock"];

              statix.enable = true;
            };

            settings = {statix.ignore = [".direnv/*"];};
          };
        };
      };
    };
}
