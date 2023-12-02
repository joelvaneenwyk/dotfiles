--
-- Clink parsers for Mycelio dotfiles project
--
-- The documentation for parsers (see https://chrisant996.github.io/clink/clink.html) is perhaps
-- the best source but be aware that some of this was written for the original clink so some of this
-- uses outdated syntax.
--

--
-- Initialization script for Windows
--

if not clink then
    -- E.g. some unit test systems will run this module *outside* of Clink.
    return
end

local parser = clink.arg.new_parser
clink.argmatcher("setup"):addflags("-f", "-c", "--clean", "--force"):addarg({"clean", "docker"})
