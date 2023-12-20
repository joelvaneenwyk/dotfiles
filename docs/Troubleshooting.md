# Windows

## PowerShell Launches New Window

**Behavior:** Every time you run any command in PowerShell, it pops up a new window. This means that even simple commands like 'dir' will not work.

This can, perhaps, be caused by many things but the only case seen while working on `dotfiles` has been due to an incorrect/empty `PATHEXT`.

* [command line - What is the default value of the PATHEXT environment variable for Windows? - Super User](https://superuser.com/questions/1027078/what-is-the-default-value-of-the-pathext-environment-variable-for-windows)
* [powershell - Suppressing The Command Window Opening When Using Start-Process - Stack Overflow](https://stackoverflow.com/questions/35113917/suppressing-the-command-window-opening-when-using-start-process)
* [Why powershell runs executables in separate window? - Server Fault](https://serverfault.com/questions/402083/why-powershell-runs-executables-in-separate-window)

# Unix / Linux

## Why do you need ./ (dot-slash) before executable or script name to run it in bash?

Hit this a few times debugging issues in scripts where they assue that '.' is in the PATH. However, it's not actually recommended to have current directory (dot `.`) in your PATH as it is a security risk. See [stackoverflow.com/a/6331085](https://stackoverflow.com/a/6331085)