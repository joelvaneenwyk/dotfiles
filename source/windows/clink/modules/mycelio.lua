--
-- Clink parsers for Mycelio dotfiles project
--
-- The documentation for parsers is perhaps the best source (see https://chrisant996.github.io/clink/clink.html) but be aware
-- that some of this was written for the original clink so some of this uses outdated syntax.
--

require("arghelper")

local setup_commands = {"clean", "docker"}
local common_flags = {
    {"--force", "-f", "Force overwrite and/or update during setup."},
    {"--clean", "-d", "Delete any intermediate files or artifacts."},
    {"--help", "Shows help about the selected command"}, {hide = true, "-?"},
    {hide = true, "--wait", "Prompts the user to press any key before exiting"},
    {hide = true, "--disable-interactivity", "Disable interactive prompts"},
    {hide = true, "--verbose", "Enables verbose logging during setup"}
}
clink.argmatcher("setup"):_addexarg(setup_commands):_addexflags({common_flags})
