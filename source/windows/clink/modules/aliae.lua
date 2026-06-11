--
-- Clink integration for aliae (shell alias manager)
--
-- https://aliae.dev/docs/
--

local t = mycelio_timer_start()

local aliae_path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Programs\\aliae\\bin\\aliae.exe"

if not os.isfile(aliae_path) then
    logger.warning('aliae not found: ' .. aliae_path)
    return nil
end

local result = mycelio_cached_init("aliae", aliae_path, "init cmd")
if result and #result > 0 then
    load(result)()
    logger.info('Initialized aliae.')
else
    logger.warning('Failed to setup aliae')
end

mycelio_timer_stop("aliae", t)
return result
