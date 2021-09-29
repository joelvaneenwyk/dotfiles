local script_dir = path.normalise(debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/linux/.poshthemes/mycelio.omp.json")
local local_ohmyposh_executable = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe")
local ohmyposh_executable = ""

if not os.isfile(local_ohmyposh_executable) then
    print('[clink] Oh My Posh not found: ' .. local_ohmyposh_executable)
elseif not os.isfile(mycelio_config) then
    print('[clink] Oh My Posh config missing: ' .. mycelio_config)
else
    io.popen(local_ohmyposh_executable .. " --version")
    if not os.geterrorlevel == 0 then
        print('[clink] WARNING: Oh My Posh version test failed: \'' .. local_ohmyposh_executable .. '\'')
    else
        print('[clink] Using Oh My Posh: \'' .. local_ohmyposh_executable .. '\'')
        ohmyposh_executable = local_ohmyposh_executable
    end
end

local ohmyposh_executable_prompt = clink.promptfilter(1)
function ohmyposh_executable_prompt:filter(prompt)
    if ohmyposh_executable ~= '' then
        prompt = io.popen(ohmyposh_executable .. " --config " .. mycelio_config):read("*a")
        return prompt, false
    end
end
