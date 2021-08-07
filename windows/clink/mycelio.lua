--[[

Clink parsers for Mycelio dotfiles project

The documentation for parsers is perhaps the best source (see https://chrisant996.github.io/clink/clink.html) but be aware
that some of this was written for the original clink so some of this uses outdated syntax.

]]

local parser = clink.arg.new_parser

--
-- Initialization script for Windows
--

clink.argmatcher("init")
:addflags(
    "-f")
:addarg(
    { "wsl", "clean", "docker" }
)
