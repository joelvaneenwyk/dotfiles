#
# Create development for iterating on `dotfiles` see `devcontainer.json` for options.
#

# [Choice] Debian / Ubuntu version (use Debian 11/9, Ubuntu 18.04/21.04 on local arm64/Apple Silicon): debian-11, debian-10, debian-9, ubuntu-21.04, ubuntu-20.04, ubuntu-18.04
ARG VARIANT=ubuntu-20.04
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}
WORKDIR /src

RUN apt-get install -y --no-install-recommends nano

RUN rm "$HOME/.profile"
