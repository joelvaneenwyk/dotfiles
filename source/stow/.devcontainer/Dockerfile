# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.191.1/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version: bullseye, buster, stretch
ARG VARIANT="bullseye"

FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
sudo wget curl unzip xclip git \
software-properties-common build-essential gcc g++ make automake autoconf \
bzip2 gawk git libssl-dev make patch \
perl cpanminus perlbrew \
texinfo texlive texi2html

RUN (echo "yes"; echo ""; echo "no"; echo "exit") | sudo cpan -T || true

# Install dependencies but skip tests
RUN sudo cpanm --notest YAML Test::Output CPAN::DistnameInfo

# Perl development dependencies
RUN sudo cpanm --notest Perl::Critic

RUN sudo cpanm --notest ExtUtils::MakeMaker common::sense
RUN git clone -b master https://github.com/gitpan/IO-AIO.git
RUN cd IO-AIO \
&& perl Makefile.PL \
&& make \
&& sudo make install \
&& make test

RUN sudo cpanm --notest Moose AnyEvent AnyEvent::AIO Coro JSON Data::Dump PadWalker Scalar::Util Class::Refresh Compiler::Lexer
RUN git clone -b master https://github.com/richterger/Perl-LanguageServer.git
RUN cd Perl-LanguageServer \
&& perl Makefile.PL \
&& make \
&& sudo make install \
&& make test
