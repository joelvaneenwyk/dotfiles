# Repo Overview

Source: [Hinara/linux-vm-tools: Hyper-V Linux Guest VM Enhancements](https://github.com/Hinara/linux-vm-tools)

This repository is the home of a set of bash scripts that enable and configure an enhanced session mode on Linux VMs (Ubuntu, arch) for Hyper-V. You can learn more about this in our [blog post](https://techcommunity.microsoft.com/t5/virtualization/sneak-peek-taking-a-spin-with-enhanced-linux-vms/ba-p/382415).

## How to use the repo

You can find the original instructions here: [Ubuntu 20.04 on Hyper-V. Creating Virtual Machine | by App Engineering Lab | Medium](https://medium.com/@labappengineering/ubuntu-20-04-on-hyper-v-8888fe3ced64)

There is also some useful information about display settings at [Donovan Brown | How to run HyperV base Ubuntu VM full screen](https://www.donovanbrown.com/post/How-to-run-HyperV-base-Ubuntu-VM-full-screen).

```bash
# Follow https://techcommunity.microsoft.com/t5/virtualization/sneak-peek-taking-a-spin-with-enhanced-linux-vms/ba-p/382415
# xrdp.service not starting because address already in use: https://github.com/microsoft/linux-vm-tools/issues/94

# Get the scripts from GitHub
sudo apt-get update
sudo apt install git
git clone https://github.com/joelvaneenwyk/dotfiles ~/dotfiles
cd ~/dotfiles/source/provisioning/ubuntu/18.04/

#Make the scripts executable and run them...
sudo chmod +x install.sh
sudo ./install.sh
sudo reboot
cd ~/linux-vm-tools/ubuntu/18.04/
sudo ./install.sh
sudo systemctl enable xrdp.service
sudo gedit /etc/xrdp/xrdp.ini
# change these two lines: port=vsock://-1:3389 and use_vsock=false
sudo systemctl start xrdp.service
sudo shutdown -h 0
```

Once you execute the above, run the following in PowerShell with administrator privileges.

```powershell
Set-VM -VMName <your_vm_name>  -EnhancedSessionTransportType HvSocket
```

Onboarding instructions for Ubuntu can be found on the [repo wiki](https://github.com/Microsoft/linux-vm-tools/wiki/Onboarding:-Ubuntu).

## FAQ

Frequently Asked Questions for this repo can be found on the [repo wiki](https://github.com/Microsoft/linux-vm-tools/wiki/FAQ).

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
