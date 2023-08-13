-- luacheck: globals clink.promptcoroutine io.popenyield

-- Custom script to setup Oh My Posh.
-- @type fun(string):string?
local function omp_cli(omp, config_file)
    local file_handle
    local pclose

    ---@type string?
    local out = nil
    local loaded = false

    local args = '"' .. omp .. '" init cmd'
    -- args = '"' .. oh_my_posh_executable .. '"' .. ' init cmd --config "' .. mycelio_config .. '"'

    local command = '' .. args .. ''
    local _, ismain = coroutine.running()

    print('##[cmd] ' .. command)
    if ismain then
        file_handle, pclose = io.popen(command)
    else
        file_handle, pclose = io.popenyield(command)
    end

    if file_handle then
        out = ''
        while (true) do
            local line = file_handle:read("*line")
            if not line then
                break
            end
            out = out .. line
        end

        file_handle:close()

        local exit_code = 99
        local is_ok = false
        local result_value = nil

        if pclose then
            is_ok, result_value, exit_code = pclose()
        elseif out then
            is_ok = true
            exit_code = 0
        end

        if exit_code == 0 then
            local function_result, syntaxError = load(out, nil, "t")
            if not function_result then
                print("There was a syntax error:", syntaxError)
            else
                function_result(config_file)
                print('[clink] Initialized Oh My Posh: \'' .. omp .. '\'')
            end
        end
    end

    if exit_code == 0 then
        -- A prompt filter that adds a line feed and angle bracket.
        local bracket_prompt = clink.promptfilter(150)
        function bracket_prompt:filter(prompt)
            return prompt .. "\n → "
        end

        print('[clink] Initialized backup prompt since Oh My Posh failed.')
    end

    return out, exit_code
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

    if mycelio_config and oh_my_posh_executable then
        local lua_setup, exit_code = omp_cli(oh_my_posh_executable)
        if not exit_code == 0 then
            print('[clink] WARNING: Oh My Posh version test failed: \'' .. oh_my_posh_executable .. '\'')
        elseif not lua_setup then
            print('[clink] WARNING: Oh My Posh initialization did not return setup script: \'' ..
            oh_my_posh_executable .. '\'')
        end
    end

    return loaded
end

omp_init()
