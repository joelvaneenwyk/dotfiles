package = ".dotfiles"
version = "scm-1"
source = {
    url = "git+ssh://git@github.com/joelvaneenwyk/dotfiles.git"
}
description = {
    detailed = [[
```ansi
 ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓
 ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃
 ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛
```]],
    homepage = "https://github.com/joelvaneenwyk/dotfiles",
    license = "MIT"
}
build = {
    type = "builtin",
    modules = {
        ["packages.macos..hammerspoon.init"] = "packages\\macos\\.hammerspoon\\init.lua",
        ["source.windows.clink-completions.!init"] = "source\\windows\\clink-completions\\!init.lua",
        ["source.windows.clink-completions..init"] = "source\\windows\\clink-completions\\.init.lua",
        ["source.windows.clink-completions.angular-cli"] = "source\\windows\\clink-completions\\angular-cli.lua",
        ["source.windows.clink-completions.chocolatey"] = "source\\windows\\clink-completions\\chocolatey.lua",
        ["source.windows.clink-completions.cmd_commands"] = "source\\windows\\clink-completions\\cmd_commands.lua",
        ["source.windows.clink-completions.coho"] = "source\\windows\\clink-completions\\coho.lua",
        ["source.windows.clink-completions.completions.adb"] = "source\\windows\\clink-completions\\completions\\adb.lua",
        ["source.windows.clink-completions.completions.attrib"] =
        "source\\windows\\clink-completions\\completions\\attrib.lua",
        ["source.windows.clink-completions.completions.bat"] = "source\\windows\\clink-completions\\completions\\bat.lua",
        ["source.windows.clink-completions.completions.cmdkey"] =
        "source\\windows\\clink-completions\\completions\\cmdkey.lua",
        ["source.windows.clink-completions.completions.code"] =
        "source\\windows\\clink-completions\\completions\\code.lua",
        ["source.windows.clink-completions.completions.colortool"] =
        "source\\windows\\clink-completions\\completions\\colortool.lua",
        ["source.windows.clink-completions.completions.curl"] =
        "source\\windows\\clink-completions\\completions\\curl.lua",
        ["source.windows.clink-completions.completions.delta"] =
        "source\\windows\\clink-completions\\completions\\delta.lua",
        ["source.windows.clink-completions.completions.dirx"] =
        "source\\windows\\clink-completions\\completions\\dirx.lua",
        ["source.windows.clink-completions.completions.doskey"] =
        "source\\windows\\clink-completions\\completions\\doskey.lua",
        ["source.windows.clink-completions.completions.eza"] = "source\\windows\\clink-completions\\completions\\eza.lua",
        ["source.windows.clink-completions.completions.fastboot"] =
        "source\\windows\\clink-completions\\completions\\fastboot.lua",
        ["source.windows.clink-completions.completions.fd"] = "source\\windows\\clink-completions\\completions\\fd.lua",
        ["source.windows.clink-completions.completions.findstr"] =
        "source\\windows\\clink-completions\\completions\\findstr.lua",
        ["source.windows.clink-completions.completions.grep"] =
        "source\\windows\\clink-completions\\completions\\grep.lua",
        ["source.windows.clink-completions.completions.gsudo"] =
        "source\\windows\\clink-completions\\completions\\gsudo.lua",
        ["source.windows.clink-completions.completions.less"] =
        "source\\windows\\clink-completions\\completions\\less.lua",
        ["source.windows.clink-completions.completions.make"] =
        "source\\windows\\clink-completions\\completions\\make.lua",
        ["source.windows.clink-completions.completions.nmake"] =
        "source\\windows\\clink-completions\\completions\\nmake.lua",
        ["source.windows.clink-completions.completions.openssl"] =
        "source\\windows\\clink-completions\\completions\\openssl.lua",
        ["source.windows.clink-completions.completions.ping"] =
        "source\\windows\\clink-completions\\completions\\ping.lua",
        ["source.windows.clink-completions.completions.premake5"] =
        "source\\windows\\clink-completions\\completions\\premake5.lua",
        ["source.windows.clink-completions.completions.rg"] = "source\\windows\\clink-completions\\completions\\rg.lua",
        ["source.windows.clink-completions.completions.robocopy"] =
        "source\\windows\\clink-completions\\completions\\robocopy.lua",
        ["source.windows.clink-completions.completions.scrcpy"] =
        "source\\windows\\clink-completions\\completions\\scrcpy.lua",
        ["source.windows.clink-completions.completions.sed"] = "source\\windows\\clink-completions\\completions\\sed.lua",
        ["source.windows.clink-completions.completions.signtool"] =
        "source\\windows\\clink-completions\\completions\\signtool.lua",
        ["source.windows.clink-completions.completions.sudo"] =
        "source\\windows\\clink-completions\\completions\\sudo.lua",
        ["source.windows.clink-completions.completions.winget"] =
        "source\\windows\\clink-completions\\completions\\winget.lua",
        ["source.windows.clink-completions.completions.wt"] = "source\\windows\\clink-completions\\completions\\wt.lua",
        ["source.windows.clink-completions.completions.xcopy"] =
        "source\\windows\\clink-completions\\completions\\xcopy.lua",
        ["source.windows.clink-completions.cordova"] = "source\\windows\\clink-completions\\cordova.lua",
        ["source.windows.clink-completions.dotnet"] = "source\\windows\\clink-completions\\dotnet.lua",
        ["source.windows.clink-completions.git"] = "source\\windows\\clink-completions\\git.lua",
        ["source.windows.clink-completions.git_prompt"] = "source\\windows\\clink-completions\\git_prompt.lua",
        ["source.windows.clink-completions.kubectl"] = "source\\windows\\clink-completions\\kubectl.lua",
        ["source.windows.clink-completions.modules.JSON"] = "source\\windows\\clink-completions\\modules\\JSON.lua",
        ["source.windows.clink-completions.modules.arghelper"] =
        "source\\windows\\clink-completions\\modules\\arghelper.lua",
        ["source.windows.clink-completions.modules.clink_version"] =
        "source\\windows\\clink-completions\\modules\\clink_version.lua",
        ["source.windows.clink-completions.modules.color"] = "source\\windows\\clink-completions\\modules\\color.lua",
        ["source.windows.clink-completions.modules.funclib"] = "source\\windows\\clink-completions\\modules\\funclib.lua",
        ["source.windows.clink-completions.modules.gitutil"] = "source\\windows\\clink-completions\\modules\\gitutil.lua",
        ["source.windows.clink-completions.modules.help_parser"] =
        "source\\windows\\clink-completions\\modules\\help_parser.lua",
        ["source.windows.clink-completions.modules.matchers"] =
        "source\\windows\\clink-completions\\modules\\matchers.lua",
        ["source.windows.clink-completions.modules.multicharflags"] =
        "source\\windows\\clink-completions\\modules\\multicharflags.lua",
        ["source.windows.clink-completions.modules.path"] = "source\\windows\\clink-completions\\modules\\path.lua",
        ["source.windows.clink-completions.modules.tables"] = "source\\windows\\clink-completions\\modules\\tables.lua",
        ["source.windows.clink-completions.msbuild"] = "source\\windows\\clink-completions\\msbuild.lua",
        ["source.windows.clink-completions.net"] = "source\\windows\\clink-completions\\net.lua",
        ["source.windows.clink-completions.npm"] = "source\\windows\\clink-completions\\npm.lua",
        ["source.windows.clink-completions.nvm"] = "source\\windows\\clink-completions\\nvm.lua",
        ["source.windows.clink-completions.pip"] = "source\\windows\\clink-completions\\pip.lua",
        ["source.windows.clink-completions.pipenv"] = "source\\windows\\clink-completions\\pipenv.lua",
        ["source.windows.clink-completions.scoop"] = "source\\windows\\clink-completions\\scoop.lua",
        ["source.windows.clink-completions.spec.color_spec"] = "source\\windows\\clink-completions\\spec\\color_spec.lua",
        ["source.windows.clink-completions.spec.funclib_spec"] =
        "source\\windows\\clink-completions\\spec\\funclib_spec.lua",
        ["source.windows.clink-completions.spec.path_spec"] = "source\\windows\\clink-completions\\spec\\path_spec.lua",
        ["source.windows.clink-completions.ssh"] = "source\\windows\\clink-completions\\ssh.lua",
        ["source.windows.clink-completions.vagrant"] = "source\\windows\\clink-completions\\vagrant.lua",
        ["source.windows.clink-completions.yarn"] = "source\\windows\\clink-completions\\yarn.lua",
        ["source.windows.clink-gizmos.modules.fzf"] = "source\\windows\\clink-gizmos\\fzf.lua",
        ["source.windows.clink.modules.mycelio"] = "source\\windows\\clink\\modules\\mycelio.lua",
        ["source.windows.clink.modules.oh_my_posh"] = "source\\windows\\clink\\modules\\oh_my_posh.lua",
        ["source.windows.clink.modules.zoxide"] = "source\\windows\\clink\\modules\\zoxide.lua",
        ["source.windows.clink.profile"] = "source\\windows\\clink\\profile.lua"
    },
    copy_directories = {
        "docs"
    }
}
