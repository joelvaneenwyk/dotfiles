--
-- Clink parsers for Mycelio dotfiles project
--
-- https://aliae.dev/docs/
--

local aliae_path = "aliae"
local potential_path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Programs\\aliae\\bin\\aliae.exe"
aliae_path = potential_path

local command = '\"' .. aliae_path .. '\"' .. ' init cmd'
logger.info('##[cmd] ' .. command)
load(io.popen(command):read("*a"))()

local file = io.popen(command)
local result = nil
if file ~= nil then
    result = file:read('*a')
    load(result)()
    file:close()
    logger.info('Initialized aliae.')
else
    logger.warning('Failed to setup aliae')
end

return result
