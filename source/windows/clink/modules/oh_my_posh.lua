--
-- Clink integration for Oh My Posh (prompt theme engine)
--
-- https://ohmyposh.dev/
--

-- luacheck: globals logger mycelio_cached_init mycelio_timer_start mycelio_timer_stop
local t = mycelio_timer_start()

local function load_oh_my_posh(mycelio_root_dir)
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json")
    local exe_path = nil
    local candidates = {
        home .. "/AppData/Local/Programs/oh-my-posh/bin/oh-my-posh.exe",
        home .. "/.local/go/bin/oh-my-posh.exe",
        "C:\\Program Files (x86)\\oh-my-posh\\bin\\oh-my-posh.exe"
    }

    for _, candidate in ipairs(candidates) do
        local normalized = path.normalise(candidate)
        if os.isfile(normalized) then
            exe_path = normalized
            break
        end
    end

    if not exe_path then
        logger.error('Oh-My-Posh not found')
        return false
    end

    if not os.isfile(mycelio_config) then
        logger.error('Oh My Posh config missing: ' .. mycelio_config)
        return false
    end

    local result = mycelio_cached_init(
        "oh_my_posh",
        exe_path,
        "init cmd --config " .. mycelio_config,
        { mycelio_config }
    )

    if result and #result > 0 then
        load(result)()
        logger.info('Initialized Oh-My-Posh: "' .. exe_path .. '"')
        return true
    else
        logger.warning('Oh-My-Posh init failed')
        return false
    end
end

---@diagnostic disable-next-line: param-type-mismatch
local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../../..")
load_oh_my_posh(mycelio_root_dir)

mycelio_timer_stop("oh_my_posh", t)
