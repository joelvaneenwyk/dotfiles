--
-- Clink parsers for Mycelio dotfiles project
--
-- https://aliae.dev/docs/
--

local file = io.popen('aliae init cmd')
if file ~= nil then
    local qresult = file:read('*a')
    local ok = file:close()

    if ok then
        result = load(qresult)()
        logger.info('Initialized aliae.')
    end
else
    logger.warning('Failed to setup aliae')
end

return result
