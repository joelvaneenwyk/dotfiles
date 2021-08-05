FROM ubuntu:latest

RUN apt update
RUN apt install -y git stow sudo micro

RUN useradd -ms /bin/bash default

USER default
WORKDIR /home/default

# Update SSH file so that we can pull from GitHub non-interactively
RUN mkdir /home/default/.ssh
RUN echo "Host github.com" >| "/home/default/.ssh/config"
RUN echo "    StrictHostKeyChecking no" >> "/home/default/.ssh/config"
RUN chmod 400 "/home/default/.ssh/config"

# Clone latest version mostly just to get the `.git` files in place for updating later
RUN git clone --recursive https://github.com/joelvaneenwyk/dotfiles.git || true

COPY --chown=default ./ ./dotfiles
RUN (cd dotfiles && stow --adopt bash)
