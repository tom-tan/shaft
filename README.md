# dlang-for-remote-container-template
[![CI](https://github.com/tom-tan/dlang-for-remote-container-template/actions/workflows/ci.yml/badge.svg)](https://github.com/tom-tan/dlang-for-remote-container-template/actions/workflows/ci.yml)

# What is this?
This is a template to develop [D](https://dlang.org/) applications with [Visual Studio Code](https://code.visualstudio.com/) with [remote container](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

## How to use

- Push the `Use this template` button in this repository and create a new repository for you.
- Clone it to your local machine.
- Open the cloned repository with remote container extension of VSCode.
- Have fun!
  - Remember the followings:
    - Fix [LICENSE](LICENSE) file and a badge link in [README.md](README.md)
    - Remove [build-container.yml](.github/workflows/build-container.yml) not to consume workflow run time in Github Actions

## What is provided in this template?
- D compiler and utilities such as `dub` and `rdmd` (via [`install.sh`](https://dlang.org/install.html))
  - This template uses [`ghcr.io/tom-tan/ldc`](https://github.com/tom-tan/dlang-for-remote-container-template/pkgs/container/ldc) (based on [wilzbach/dlang-docker](https://github.com/wilzbach/dlang-docker)) to provide `ldc2` by default.
    - You can use [`ghcr.io/tom-tan/dmd`](https://github.com/tom-tan/dlang-for-remote-container-template/pkgs/container/dmd) or [`ghcr.io/tom-tan/gdc`](https://github.com/tom-tan/dlang-for-remote-container-template/pkgs/container/gdc) for other D compilers
  - See [`Dockerfile`](https://github.com/tom-tan/dlang-for-remote-container-template/blob/main/.devcontainer/Dockerfile) for details
- A setting and D extension for remote container
  - [D Language utility extension pack](https://marketplace.visualstudio.com/items?itemName=webfreak.dlang-bundle) and its default settings
  - See [`devcontainer.json`](https://github.com/tom-tan/dlang-for-remote-container-template/blob/main/.devcontainer/devcontainer.json) for details
- A CI setting for [Github Actions](https://docs.github.com/en/actions)
  - It runs `dub test` if the setting for dub is available for each commit to `main` branch, for each tag and for each pull request
  - It is automatically enabled in the cloned repositories
  - This template also provides a badge to show the CI result in [README.md](https://github.com/tom-tan/dlang-for-remote-container-template/blob/main/README.md)
  - See [ci.yml](https://github.com/tom-tan/dlang-for-remote-container-template/blob/main/.github/workflows/ci.yml) for detatils
- A daily CI setting that builds `ghcr.io/tom-tan/ldc`, `ghcr.io/tom-tan/dmd` and `ghcr.io/tom-tan/gdc` for latest release for each compiler
  - It is only enabled in this template and is disabled in the cloned repositories. See [build-container.yml](https://github.com/tom-tan/dlang-for-remote-container-template/blob/main/.github/workflows/build-container.yml) for details
  - Remove [build-container.yml](.github/workflows/build-container.yml) when you create a repository from this template

## License
This repository is licensed under the Unlicense (a.k.a. Public Domain).

Please fix [LICENSE](LICENSE) file when you create a repository from this template.

