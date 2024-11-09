{
  description = "FHS Dev Shell for Swift";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";

    swift-bin-aarch64 = {
      url = "https://download.swift.org/swift-6.0.1-release/debian12-aarch64/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-debian12-aarch64.tar.gz";
      flake = false;
    };

    swift-bin-x86_64 = {
      url = "https://download.swift.org/swift-6.0.1-release/debian12/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-debian12.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, swift-bin-x86_64, swift-bin-aarch64 }: 
    let
      swift = {src, system}: 
        with import nixpkgs { inherit system; };
        stdenv.mkDerivation {
          inherit src;
          dontAutoPatchelf = true;
          outputs = [ "out" "bin" "include" "lib" "libexec" "local" "share" ];
          name = "swift";
          version = "6.0.1";
          unpackPhase = ''
            mkdir -p usr
            cp -r ${src}/usr/* usr/
          '';

          patchPhase = ''
            patchelf --set-rpath '$ORIGIN/../linux' usr/lib/swift/pm/PluginAPI/libPackagePlugin.so
          '';

          installPhase = ''
            cp -r usr $out
            cp -r usr/bin $bin
            cp -r usr/include $include
            cp -r usr/lib $lib
            cp -r usr/libexec $libexec
            cp -r usr/local $local
            cp -r usr/share $share
          '';
          patchPhase = '''';
        };

      fhs = { swift-der, system}:
        with import nixpkgs { inherit system; }; 
        buildFHSUserEnv {
          name = "fhs-swift";
          targetPkgs = pkgs: [ 
            pkgs.python3
            pkgs.libxml2
            swift-der
            pkgs.libuuid 
            pkgs.sqlite 
            pkgs.ncurses 
            pkgs.pkg-config
            pkgs.gcc-unwrapped
            pkgs.glibc.dev
            pkgs.bintools-unwrapped
            pkgs.libz
            pkgs.git
            pkgs.curl
          ];
          # Fixes 'libncurses.so.6 not found'. There's probably a better way?
          profile = ''
            export LD_LIBRARY_PATH="/usr/lib64/:/usr/lib/:$LD_LIBRARY_PATH"
          '';
        };

      aarch64FHS = fhs { 
        system = "aarch64-linux";
        swift-der = swift { 
          system = "aarch64-linux";
          src = swift-bin-aarch64;
        };
      };

      x86_64FHS = fhs {
        system = "x86_64-linux";
        swift-der = swift {
          system = "x86_64-linux";
          src = swift-bin-x86_64;
        };
      };
    in 
      {
        devShells.aarch64-linux.default = aarch64FHS.env;
        devShells.x86_64-linux.default = x86_64FHS.env;
      };
}
