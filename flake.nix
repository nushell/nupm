/*
NOTE:
If you make changes to this file please run `nix fmt` and `nix flake check`
when you're done.

To update this flake run `nix flake update`.

To build `nupm` run `nix build .#nupm-lib`.

To test `nupm` run `nix flake check`.

To enter a development shell run `nix develop`.
*/
{
  description = "A manager for Nushell packages.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        packages = with pkgs; rec {
          # This packages nupm as a library where it can be imported and used a
          # module.
          nupm-lib = stdenvNoCC.mkDerivation {
            name = "nupm";
            src = ./.;
            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/nupm
              mv ./* $out/share/nupm

              runHook postInstall
            '';
          };

          # This packages the test functionality and makes it portable. You can
          # test your own applications with `nix run github:nushell/nupm#nupm-test`
          nupm-test = writeShellApplication {
            runtimeInputs = [nupm-lib nushell];
            name = "nupm-test";
            text = ''
              nu --no-config-file \
                --commands '
                  use ${nupm-lib}/share/nupm/nupm

                  nupm test
                '
            '';
          };
        };

        # This is the formatter for `.nix` files. Eventually, `nufmt` and
        # `treefmt` could be included for tree-wide formatting.
        formatter = pkgs.alejandra;

        # These are the nix tests. At the moment, this is only wrapping `nupm
        # test` but can have many tests including `pre-commit` checks,
        # formatters, linters, etc.
        checks = {
          nupm-tests = with pkgs;
            stdenvNoCC.mkDerivation {
              inherit system;
              name = "nupm tests";
              src = ./.;
              buildInputs = [nushell];

              buildPhase = ''
                nu --no-config-file \
                  --commands '
                    use ./nupm

                    nupm test
                  '
              '';

              installPhase = ''
                touch $out
              '';
            };
        };

        # This holds reproducible developer environments. Eventually this can
        # also have an output for `nushell-nightly` if it's needed for
        # development.
        devShells = with pkgs; {
          default = mkShell {
            buildInputs = [nushell];

            # This can also include environment variables ex:
            # NU_LIB_DIRS = ../modules;
          };
        };
      };
    };
}
