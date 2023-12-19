--[[

Clink profile for 'dotfiles' project.

See https://chrisant996.github.io/clink/clink.html for documentation. This is originally based
on the Cmder boot script (see https://github.com/cmderdev/cmder/blob/master/config/cmder.lua) but has
been somewhat heavily modified and also just out of date with most recent version.

]]

local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local color_cyan = "\x1b[36m"
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

profile_settings = { extension_npm_cache = 1, extension_npm = 1 }
--------------------------------------------------------------------------------

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

logger = {
    debug = mycelio_log_debug,
    info = mycelio_log_info,
    warning = mycelio_log_warning,
    error = mycelio_log_error
}


---
-- Resolves closest directory location for specified directory.
-- Navigates subsequently up one level and tries to find specified directory
-- @param  {string} path    Path to directory will be checked. If not provided
--                          current directory will be used
-- @param  {string} dirname Directory name to search for
-- @return {string} Path to specified directory or nil if such dir not found

local function get_dir_contains(path, dirname)
    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i - 1)
        end
        return prefix
    end

    -- Navigates up one level
    local function up_one_level(path)
        if path == nil then
            path = '.'
        end
        if path == '.' then
            path = clink.get_cwd()
        end
        return pathname(path)
    end

    -- Checks if provided directory contains git directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then
            path = '.'
        end
        local found_dirs = clink.find_dirs(path .. '/' .. specified_dir)
        if #found_dirs > 0 then
            return true
        end
        return false
    end

    -- Set default path to current directory
    if path == nil then
        path = '.'
    end

    -- If we're already have .git directory here, then return current path
    if has_specified_dir(path, dirname) then
        return path .. '/' .. dirname
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = up_one_level(path)
        if parent_path == path then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

local function get_hg_dir(path)
    return get_dir_contains(path, '.hg')
end

local function get_git_dir(path)
    return get_dir_contains(path, '.git')
end

---
-- Find out current branch
-- @return {false|mercurial branch name}
---
function get_hg_branch()
    for line in io.popen("hg branch 2>nul"):lines() do
        local m = line:match("(.+)$")
        if m then
            return m
        end
    end

    return false
end

---
-- Find out current branch
-- @return {false|git branch name}
---
function get_git_branch()
    for line in io.popen("git branch 2>nul"):lines() do
        local m = line:match("%* (.+)$")
        if m then
            return m
        end
    end

    return false
end

---
-- Get the status of working dir
-- @return {bool}
---
function get_git_status()
    return os.execute("git diff --quiet --ignore-submodules HEAD 2>nul")
end

function add_modules(input_path)
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

-- A prompt filter that appends the current git branch.
local git_branch_prompt = clink.promptfilter(65)
function git_branch_prompt:filter(prompt)
    local line = io.popen("git branch --show-current 2>nul"):read("*a")
    local branch = line:match("(.+)\n")
    if branch then
        return prompt .. " " .. color_cyan .. "[" .. branch .. "]" .. color_normal
    end
end

-- A prompt filter that adds a line feed and angle bracket.
local bracket_prompt = clink.promptfilter(150)
function bracket_prompt:filter(prompt)
    return prompt .. "\n → "
end

add_modules(mycelio_root_dir .. "/source/windows/clink/modules/")
add_modules(mycelio_root_dir .. "/source/windows/clink-completions/")
add_modules(mycelio_root_dir .. "/source/windows/clink-gizmos/")
