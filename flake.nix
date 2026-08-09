{
  description = "tmux-sessionizer - fuzzy-find directories and open them as tmux sessions";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = tmux-sessionizer;
        tmux-sessionizer = pkgs.stdenvNoCC.mkDerivation {
          pname = "tmux-sessionizer";
          version = "0.1.0";
          src = self;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall
            install -Dm755 tmux-sessionizer find-session open-ssh -t $out/bin
            runHook postInstall
          '';

          postFixup =
            let
              runtimeDeps =
                with pkgs;
                [
                  tmux
                  fzf
                  findutils
                  gnugrep
                  gnused
                  coreutils
                ]
                ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.procps ];
            in
            ''
              for bin in $out/bin/*; do
                wrapProgram "$bin" --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
              done
            '';

          meta = {
            description = "Fuzzy-find directories and open them as tmux sessions";
            mainProgram = "tmux-sessionizer";
            platforms = systems;
          };
        };
      });

      overlays.default = final: prev: {
        tmux-sessionizer = self.packages.${final.stdenv.hostPlatform.system}.tmux-sessionizer;
      };
    };
}
