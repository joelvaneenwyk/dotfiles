--
-- Clink integration for mise (runtime version manager)
--
-- https://mise.jdx.dev/
--

local t = mycelio_timer_start()

local mise_path = os.getenv("MISE_PATH")
if not mise_path then
    local appdata_path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Programs\\mise\\bin\\mise.exe"
    if os.isfile(appdata_path) then
        mise_path = appdata_path
    end
end

if not mise_path or not os.isfile(mise_path) then
    logger.warning('mise not found')
    return nil
end

local result = mycelio_cached_init("mise", mise_path, "activate cmd")
if result and #result > 0 then
    load(result)()
    logger.info('Initialized mise.')
else
    logger.warning('Failed to setup mise')
end

mycelio_timer_stop("mise", t)
return result
