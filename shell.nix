# adapted from https://github.com/tweag/jupyterWith/blob/master/example/Python/shell.nix
let
  pkgs = import <nixpkgs> {};

  python = pkgs.poetry2nix.mkPoetryEnv {
    poetrylock = ./poetry.lock;
    projectDir = ./.;
  };

  pyproject =
    builtins.fromTOML (builtins.readFile ./pyproject.toml);
  depNames = builtins.attrNames pyproject.tool.poetry.dependencies;

  # Jupyter setup
  # jupyterLibPath = ../..;
  # jupyter = import jupyterLibPath {};
  jupyter = import (builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "f64a2fd6a7b0cff8b3cb874641bef3ebd96d680f";
  }) {};


  iPythonWithPackages = jupyter.kernels.iPythonWith {
    name = "test";
    python3 = python;
    packages = p:
      let
        # Building the local package using the standard way.
        myPythonPackage = p.buildPythonPackage {
          pname = "test";
          version = "0.1.0";
          src = ./test;
        };
        # Getting dependencies using Poetry.
        poetryDeps =
          builtins.map (name: builtins.getAttr name p) depNames;
      in
        [ myPythonPackage ] ++ poetryDeps ;
  };

  jupyterlabWithKernels = jupyter.jupyterlabWith {
    kernels = [ iPythonWithPackages ];
    extraPackages = p: [p.hello];
  };
in
  jupyterlabWithKernels.env
