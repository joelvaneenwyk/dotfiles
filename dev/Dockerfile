FROM ubuntu:latest

RUN apt update
RUN apt install -y git stow

RUN useradd -ms /bin/bash default

USER default
WORKDIR /home/default

RUN mkdir /home/default/.ssh
RUN echo "Host github.com" >| "/home/default/.ssh/config"
RUN echo "    StrictHostKeyChecking no" >> "/home/default/.ssh/config"
RUN chmod 400 "/home/default/.ssh/config"
