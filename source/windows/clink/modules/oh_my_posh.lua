local function load_oh_my_posh(mycelio_root_dir)
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json")
    local local_oh_my_posh_executable = ""
    local loaded = false
    local values = {
        home .. "/AppData/Local/Programs/oh-my-posh/bin/oh-my-posh.exe", home .. "/.local/go/bin/oh-my-posh.exe",
        "C:\\Program Files (x86)\\oh-my-posh\\bin\\oh-my-posh.exe"
    }

    for _, value in pairs(values) do
        ---@diagnostic disable-next-line: undefined-field
        if os.isfile(local_oh_my_posh_executable) then
            break
        else
            if local_oh_my_posh_executable ~= "" then
                logger.debug('Oh-My-Posh not here: ' .. local_oh_my_posh_executable)
            end
            local_oh_my_posh_executable = path.normalise(value)
        end
    end

    ---@diagnostic disable-next-line: undefined-field
    if not os.isfile(local_oh_my_posh_executable) then
        logger.error('Oh-My-Posh not found: ' .. local_oh_my_posh_executable)
    end

    if not os.isfile(mycelio_config) then
        logger.error('Oh My Posh config missing: ' .. mycelio_config)
    end

    if os.isfile(local_oh_my_posh_executable) and os.isfile(mycelio_config) then
        local omp = "\"" .. local_oh_my_posh_executable .. "\""
        local version_process = io.popen(omp .. " --version")
        local version = nil

        ---@diagnostic disable-next-line: undefined-field
        if version_process ~= nil then
            version = version_process:read("*a")
        end

        if version == nil then
            logger.warning('Failed to get Oh-My-Posh version: ' .. omp)
        else
            local process = io.popen(omp .. " init cmd --config " .. mycelio_config)
            if process ~= nil then
                local command = process:read("*a")
                load(command)()
                logger.info('Initialized Oh-My-Posh: ' .. omp)
            else
                logger.warning('Oh-My-Posh init failed: ' .. omp)
            end
            loaded = true
        end
    end

    return loaded
end

---@diagnostic disable-next-line: param-type-mismatch
local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../../..")
load_oh_my_posh(mycelio_root_dir)
