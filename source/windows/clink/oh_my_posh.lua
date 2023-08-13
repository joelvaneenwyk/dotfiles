-- luacheck: globals clink.promptcoroutine io.popenyield

-- Custom script to setup Oh My Posh.
-- @type fun(string):string?
local function omp_cli(omp, config_file)
    local omp_path = path.normalise(omp, '/')
    omp_path = 'oh-my-posh'
    local config_file_path = path.normalise(config_file, '/')
    local command = omp_path .. ' init cmd --config ' .. config_file_path

    local _, ismain = coroutine.running()
    local file_handle = nil
    local pclose = nil

    print('##[cmd] ' .. command)
    if ismain then
        file_handle, pclose = io.popen(command)
    else
        file_handle, pclose = io.popenyield(command)
    end

    ---@type string?
    local out = nil

    if file_handle then
        out = file_handle:read("*a")
        file_handle:close()

        local exit_code = 99
        local is_ok = false

        if pclose then
            local _result_value = nil
            is_ok, _result_value, exit_code = pclose()
        elseif out then
            is_ok = true
            exit_code = 0
        end

        if not is_ok or exit_code ~= 0 then
            out = nil
        end
    end

    return out
end

local function omp_init()
    ---@type string
    local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])

    ---@type string
    local mycelio_root_dir = path.normalise(script_dir .. "../../..")

    local home = os.getenv("HOME") or os.getenv("USERPROFILE") or "~"

    ---@type string?
    local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json", '\\')

    ---@type boolean
    local loaded = false

    ---@type string
    local local_oh_my_posh_executable = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe", '\\')

    ---@type string
    local global_exe = path.normalise([[C:/Program Files (x86)/oh-my-posh/bin/oh-my-posh.exe]], '\\')

    ---@type string?
    local oh_my_posh_executable = nil

    if os.isfile(global_exe) then
        oh_my_posh_executable = global_exe
    elseif os.isfile(local_oh_my_posh_executable) then
        oh_my_posh_executable = local_oh_my_posh_executable
    end

    if not os.isfile(oh_my_posh_executable) then
        print('[clink] Oh My Posh not found: ' .. oh_my_posh_executable)
        oh_my_posh_executable = nil
    end

    if not os.isfile(mycelio_config) then
        print('[clink] Oh My Posh config missing: ' .. mycelio_config)
        mycelio_config = nil
    end

    local result = nil

    if mycelio_config and oh_my_posh_executable then
        result = omp_cli(oh_my_posh_executable, mycelio_config)
    end

    return result
end

local omp_init_script = omp_init()

if omp_init_script then
    local function_result, syntaxError = load(omp_init_script)

    if not function_result then
        print("There was a syntax error:", syntaxError)
    else
        print('[clink] Initialized Oh My Posh.')
        function_result()
    end
else
    print('[clink] WARNING: Oh My Posh initialization did not return setup script.')

    -- A prompt filter that adds a line feed and angle bracket.
    local bracket_prompt = clink.promptfilter(150)
    function bracket_prompt:filter(prompt)
        return prompt .. "\n → "
    end

    print('[clink] Initialized backup prompt since Oh My Posh failed.')
end
