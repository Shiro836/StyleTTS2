{
    description = "StyleTTS2";

    nixConfig = {
        extra-substituters = [
            "https://cuda-maintainers.cachix.org"
        ];
        extra-trusted-public-keys = [
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
    };

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs?ref=23.11";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
        nixpkgs-unfree.url = "github:SomeoneSerge/nixpkgs-unfree";
        flake-utils.url = "github:numtide/flake-utils";
    };

    inputs.nixpkgs-unfree.inputs.nixpkgs.follows = "nixpkgs";

    outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = import nixpkgs {
                    inherit system;
                    config = {
                        allowUnfree = true;
                        segger-jlink.acceptLicense = true;
                        acceptCudaLicense = true;
                        cudaSupport = true;
                        cudaVersion = "12";
                    };
                    inherit (pkgs.cudaPackages) cudatoolkit;
                    inherit (pkgs.linuxPackages) nvidia_x11;
                };

                pkgs_unstable = import nixpkgs-unstable {
                    inherit system;
                    config = {
                        allowUnfree = true;
                        segger-jlink.acceptLicense = true;
                        acceptCudaLicense = true;
                        cudaSupport = true;
                        cudaVersion = "12";
                    };
                    inherit (pkgs.cudaPackages) cudatoolkit;
                    inherit (pkgs.linuxPackages) nvidia_x11;
                };

                einops_exts = pkgs.python311Packages.buildPythonPackage rec {
                    name = "einops_exts";
                    src = builtins.fetchGit {
                        url = "https://github.com/lucidrains/einops-exts.git";
                        ref = "main";
                        rev = "a61d8d5c0ba10b6d9386b924177f528799627924";
                    };
                    buildInputs = with pkgs.python311.pkgs; [
                        pip
                        einops
                        torch
                        setuptools
                        wheel
                    ];
                };

                monotonic_align = pkgs.python311Packages.buildPythonPackage rec {
                    name = "monotonic_align";
                    src = builtins.fetchGit {
                        url = "https://github.com/resemble-ai/monotonic_align";
                        ref = "master";
                        rev = "78b985be210a03d08bc3acc01c4df0442105366f";
                    };
                    buildInputs = with pkgs.python311.pkgs; [
                        pip
                        numpy
                        cython
                        torch
                    ];
                };

                pythonEnv = pkgs.python311.withPackages (p: with p; [
                    jupyter
                    ipython

                    flask
                    soundfile
                    munch
                    pydub
                    pyyaml
                    librosa
                    nltk
                    matplotlib
                    accelerate
                    transformers
                    einops
                    einops_exts
                    tqdm
                    typing
                    typing-extensions
                    phonemizer

                    torch
                    torchvision
                    torchaudio

                    monotonic_align
                ]);

            in
            {
                devShells.default = pkgs.mkShellNoCC {
                    buildInputs = with pkgs;[
                        git gitRepo gnupg autoconf curl
                        procps gnumake util-linux m4 gperf unzip
                        cudatoolkit linuxPackages.nvidia_x11
                        libGLU libGL
                        xorg.libXi xorg.libXmu freeglut
                        xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib 
                        ncurses5 stdenv.cc binutils

                        einops_exts
                        monotonic_align
                        pythonEnv
                    ];

                    packages = with pkgs; [
                        ffmpeg
                        espeak-ng
                    ];

                    shellHook = ''
                        export PYTHONPATH="${pythonEnv}/${pythonEnv}/bin/python"/${pythonEnv.sitePackages}
                        export CUDA_PATH=${pkgs.cudatoolkit}
                        export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
                        export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
                        export EXTRA_CCFLAGS="-I/usr/include"
                    '';
                };
            }
        );
}
