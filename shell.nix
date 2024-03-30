{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
    config.segger-jlink.acceptLicense = true;
} }:
let

einops_exts = pkgs.python311Packages.buildPythonPackage rec {
    name = "einops_exts";
    src = builtins.fetchGit {
      url = "https://github.com/lucidrains/einops-exts.git";
      ref = "refs/heads/main";
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
      ref = "refs/heads/master";
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
    torch
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

in pkgs.mkShell {
    buildInputs = [
        einops_exts
        monotonic_align
        pythonEnv
    ];
    shellHook = ''
        PYTHONPATH=${pythonEnv}/${pythonEnv.sitePackages}
        export CUDA_PATH=${pkgs.cudatoolkit}
        export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
        export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
        export EXTRA_CCFLAGS="-I/usr/include"
        jupyter notebook
    '';

    packages = with pkgs; [
        ffmpeg
        espeak-ng
    ];
}
