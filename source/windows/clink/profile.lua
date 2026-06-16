--[[
===============================================------
Clink profile for 'dotfiles' project.

See https://chrisant996.github.io/clink/clink.html for documentation. This is originally based
on the Cmder boot script (see https://github.com/cmderdev/cmder/blob/master/config/cmder.lua) but has
been somewhat heavily modified and also just out of date with most recent version.
===============================================------
--]]

local _profile_start = os.clock()
local _profile_timings = {}
local _profile_cache_hits = 0
local _profile_cache_misses = 0

-- luacheck: globals mycelio_log mycelio_log_debug mycelio_log_info mycelio_log_warning mycelio_log_error logger self
-- luacheck: globals mycelio_cached_init mycelio_timer_start mycelio_timer_stop
function mycelio_log(message, level)
    local output_message = "[clink] "
    local should_print_to_console = true

    if level == nil then
        level = 1
    end

    if level >= 4 then
        output_message = output_message .. "debug "
        if not ((settings ~= nil and settings.get("lua.debug")) or clink.DEBUG) then
            should_print_to_console = false
        end
    elseif level == 3 then
        output_message = output_message .. "info  "
    elseif level == 2 then
        output_message = output_message .. "warn  "
    else
        output_message = output_message .. "error "
    end

    output_message = output_message .. "| " .. message

    if should_print_to_console then
        print(output_message)
        log.info(output_message)
    end

    return message
end

function mycelio_log_debug(message)
    mycelio_log(message, 4)
end

function mycelio_log_info(message)
    mycelio_log(message, 3)
end

function mycelio_log_warning(message)
    mycelio_log(message, 2)
end

function mycelio_log_error(message)
    mycelio_log(message, 1)
end

-- Timing helpers
function mycelio_timer_start()
    return os.clock()
end

function mycelio_timer_stop(name, start_time)
    local elapsed_ms = math.floor((os.clock() - start_time) * 1000 + 0.5)
    _profile_timings[name] = elapsed_ms
    return elapsed_ms
end

-- Caching utility for external tool init commands
local _cache_dir = nil
local function _ensure_cache_dir()
    if _cache_dir then return _cache_dir end
    _cache_dir = os.getenv("USERPROFILE") .. "\\.cache\\clink"
    local probe = io.open(_cache_dir .. "\\.probe", "w")
    if probe then
        probe:close()
        os.remove(_cache_dir .. "\\.probe")
    else
        os.execute('mkdir "' .. _cache_dir .. '" 2>nul')
    end
    return _cache_dir
end

local function _get_file_fingerprint(filepath)
    local f = io.open(filepath, "rb")
    if not f then return nil end
    local size = f:seek("end")
    f:close()
    return filepath .. "|" .. tostring(size)
end

function mycelio_cached_init(tool_name, exe_path, command_args, extra_deps)
    local cache_dir = _ensure_cache_dir()
    local cache_file = cache_dir .. "\\" .. tool_name .. ".lua"
    local fingerprint_file = cache_dir .. "\\" .. tool_name .. ".fingerprint"

    local current_fp = _get_file_fingerprint(exe_path) or ""
    if extra_deps then
        for _, dep in ipairs(extra_deps) do
            local dep_fp = _get_file_fingerprint(dep) or ""
            current_fp = current_fp .. "\n" .. dep_fp
        end
    end

    -- Check if cache is valid
    local cached_fp = nil
    local fpf = io.open(fingerprint_file, "r")
    if fpf then
        cached_fp = fpf:read("*a")
        fpf:close()
    end

    if cached_fp and cached_fp == current_fp then
        local cf = io.open(cache_file, "r")
        if cf then
            local content = cf:read("*a")
            cf:close()
            if content and #content > 0 then
                _profile_cache_hits = _profile_cache_hits + 1
                logger.debug("Cache hit for " .. tool_name)
                return content
            end
        end
    end

    -- Cache miss - run the command
    _profile_cache_misses = _profile_cache_misses + 1
    local command = '"' .. exe_path .. '" ' .. command_args
    logger.info('##[cmd] ' .. command)

    local file = io.popen(command)
    if not file then
        logger.warning('Failed to run: ' .. command)
        return nil
    end

    local result = file:read('*a')
    file:close()

    if result and #result > 0 then
        local cf = io.open(cache_file, "w")
        if cf then
            cf:write(result)
            cf:close()
        end
        local fpf_w = io.open(fingerprint_file, "w")
        if fpf_w then
            fpf_w:write(current_fp)
            fpf_w:close()
        end
    end

    return result
end

local color_normal = "\x1b[m"
local local_settings = {
    color_vsc_unknown = "\x1b[30;1m",
    color_vsc_clean = "\x1b[1;37;40m",
    color_vsc_dirty = "\x1b[31;1m",
    color_prompt = "\x1b[93m",
    color_lambda = "\x1b[1;30;40m\x1b[1m",
    color_console = "\x1b[m",
    hg_status_detection = false,
    benchmark = false
}

logger = {
    debug = mycelio_log_debug,
    info = mycelio_log_info,
    warning = mycelio_log_warning,
    error = mycelio_log_error
}

local function add_modules(input_path)
    local profile_settings = {
        extension_npm_cache = 1,
        extension_npm = 1,
    }
    local completions_dir = path.normalise(input_path)
    logger.debug('Loading modules from path: "' .. completions_dir .. '"')
    for _, lua_module in ipairs(clink.find_files(completions_dir .. '*.lua')) do
        if profile_settings[ "extension_" .. lua_module:match [[(.*).lua$]] ] ~= -1 then
            if not string.match(lua_module, '^_.*') then
                local filename = completions_dir .. lua_module
                dofile(filename)
                logger.debug('Module loaded: "' .. lua_module .. '"')
            end
        end
    end
    logger.info('Added all modules from path: "' .. completions_dir .. '"')
end

local cwd_prompt = clink.promptfilter(30)
function cwd_prompt:filter(_) -- luacheck: no unused args
    ---@diagnostic disable-next-line: undefined-field
    return local_settings.color_prompt .. os.getcwd() .. color_normal
end

-- A prompt filter that adds a line feed and angle bracket.
local bracket_prompt = clink.promptfilter(150)
function bracket_prompt:filter(prompt) -- luacheck: no unused args
    return prompt .. "\n → "
end

local function load_modules()
    local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
    local mycelio_root_dir = path.normalise(script_dir .. "../../..")

    -- Defer completions and gizmos to after first prompt
    local completions_path = mycelio_root_dir .. "/source/windows/clink-completions/"
    local gizmos_path = mycelio_root_dir .. "/source/windows/clink-gizmos/"

    -- Ensure arghelper and other shared modules are available for require()
    local completions_modules = completions_path .. "modules/?.lua"
    if not package.path:find(completions_modules, 1, true) then
        package.path = completions_modules .. ";" .. package.path
    end

    local deferred_loaded = false

    if clink.onbeginedit then
        clink.onbeginedit(function()
            if deferred_loaded then return end
            deferred_loaded = true

            local t = mycelio_timer_start()
            add_modules(completions_path)
            local completions_ms = mycelio_timer_stop("completions", t)

            t = mycelio_timer_start()
            add_modules(gizmos_path)
            local gizmos_ms = mycelio_timer_stop("gizmos", t)

            -- Calculate total boot time from batch start
            local boot_info = ""
            local start_env = os.getenv("MYCELIO_START_TIME_MS")
            local inject_env = os.getenv("MYCELIO_INJECT_TIME_MS")
            if start_env and inject_env then
                local start_ms = tonumber(start_env)
                local inject_ms = tonumber(inject_env)
                if start_ms and inject_ms then
                    local batch_time = inject_ms - start_ms
                    if batch_time < 0 then batch_time = batch_time + 86400000 end
                    local total_boot = batch_time + math.floor(os.clock() * 1000 + 0.5)
                    boot_info = ", total_boot=" .. total_boot .. "ms (batch=" .. batch_time .. "ms)"
                end
            end

            local msg = "Deferred load complete: completions=" .. completions_ms ..
                "ms, gizmos=" .. gizmos_ms .. "ms" .. boot_info
            logger.info(msg)
        end)
        _profile_timings["completions"] = "deferred"
        _profile_timings["gizmos"] = "deferred"
    else
        -- Fallback for older clink without onbeginedit
        local t = mycelio_timer_start()
        add_modules(completions_path)
        mycelio_timer_stop("completions", t)

        t = mycelio_timer_start()
        add_modules(gizmos_path)
        mycelio_timer_stop("gizmos", t)
    end

    -- Core modules (aliae, mise, oh-my-posh, zoxide) load immediately
    local t = mycelio_timer_start()
    add_modules(mycelio_root_dir .. "/source/windows/clink/modules/")
    mycelio_timer_stop("modules", t)
end

load_modules()

-- Print profile summary
local total_ms = math.floor((os.clock() - _profile_start) * 1000 + 0.5)
local cache_status = _profile_cache_misses == 0 and "cached" or
    (_profile_cache_hits == 0 and "cold" or "partial")
local parts = {}
for _, key in ipairs({"completions", "gizmos", "modules", "aliae", "mise", "oh_my_posh", "zoxide"}) do
    local v = _profile_timings[key]
    if v then
        if type(v) == "string" then
            table.insert(parts, key .. ": " .. v)
        else
            table.insert(parts, key .. ": " .. v .. "ms")
        end
    end
end
mycelio_log("Profile loaded in " .. total_ms .. "ms (" .. cache_status .. ") [" .. table.concat(parts, ", ") .. "]", 3)
