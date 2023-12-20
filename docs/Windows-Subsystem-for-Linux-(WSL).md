# Changing Default User

As described on [Manage Linux Distributions | Microsoft Docs](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#change-the-default-user-for-a-distribution) you can change your user with the following:

```cmd
<DistributionName> config --default-user <Username>
```

What this means practically is you need to find the distribution executable and run that which may not be in your path. This may be as complicated as e.g.,

```batch
"C:\Users\username\AppData\Local\Microsoft\WindowsApps\CanonicalGroupLimited.Ubuntu20.04onWindows_79rhkp1fndgsc\ubuntu2004.exe"
```
