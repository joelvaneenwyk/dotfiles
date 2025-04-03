--
-- Clink parsers for Mycelio dotfiles project
--
-- https://mise.jdx.dev/
--

local mise_path = "mise"
local debug_path = "E:\\source\\github.com\\joelvaneenwyk\\mise\\target\\debug\\mise.exe"
local appdata_path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Programs\\mise\\bin\\mise.exe"

if os.rename(debug_path, debug_path) then
    mise_path = debug_path
elseif os.rename(appdata_path, appdata_path) then
    mise_path = appdata_path
else
    mise_path = "mise"
end

local command = '\"' .. mise_path .. '\"' .. ' activate cmd'
logger.info('##[cmd] ' .. command)

local file = io.popen(command)
local result = nil
if file ~= nil then
    result = file:read('*a')
    load(result)()
    file:close()
    logger.info('Initialized mise.')
else
    logger.warning('Failed to setup mise')
end

return result
