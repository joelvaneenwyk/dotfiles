--[[
===============================================------
Clink profile for 'dotfiles' project.

See https://chrisant996.github.io/clink/clink.html for documentation. This is originally based
on the Cmder boot script (see https://github.com/cmderdev/cmder/blob/master/config/cmder.lua) but has
been somewhat heavily modified and also just out of date with most recent version.
===============================================------
--]]

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
    mycelio_log(message, 3)
end

function mycelio_log_error(message)
    mycelio_log(message, 3)
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
        -- Skip files that starts with _. This could be useful if some files should be ignored

        if profile_settings[ "extension_" .. lua_module:match [[(.*).lua$]] ] ~= -1 then
            if not string.match(lua_module, '^_.*') then
                local filename = completions_dir .. lua_module
                -- use dofile instead of require because require caches loaded modules
                -- so config reloading using Alt-Q won't reload updated modules.
                dofile(filename)
                logger.debug('Module loaded: "' .. lua_module .. '"')
            end
        end
    end
    logger.info('Added all modules from path: "' .. completions_dir .. '"')
end

local cwd_prompt = clink.promptfilter(30)
function cwd_prompt:filter(prompt)
    return local_settings.color_prompt .. os.getcwd() .. color_normal
end

-- A prompt filter that adds a line feed and angle bracket.
local bracket_prompt = clink.promptfilter(150)
function bracket_prompt:filter(prompt)
    return prompt .. "\n → "
end

local function load_modules()
    local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
    local mycelio_root_dir = path.normalise(script_dir .. "../../..")
    add_modules(mycelio_root_dir .. "/source/windows/clink/modules/")
    add_modules(mycelio_root_dir .. "/source/windows/clink-completions/")
    add_modules(mycelio_root_dir .. "/source/windows/clink-gizmos/")
end

load_modules()
