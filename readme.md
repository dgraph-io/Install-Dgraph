# Dgraph Install

This repository is home to the installation scripts that you find at `https://get.dgraph.io` and others.

Works for:

* :white_check_mark: Ubuntu 16.04 and above 
* :white_check_mark: macOS Sierra and above

<!-- Todo: Add Windows Version with Powershell version tested. -->
<!-- Todo: Add Systemd references. -->

## Install Dgraph on Linux and macOS

<!-- Todo: Add Brew formula here. -->

### Using Shell

From `https://get.dgraph.io`:
```shell
curl https://get.dgraph.io -sSf | bash
```

## Flags

<!-- Todo: Add Flags for shell. -->

## Environment Variables

<!-- Todo: Add Env Vars for shell. -->

## Install Dgraph on Windows

<!-- Todo: Add .ps1 script. -->

### Using Powershell

This script needs to be executed with ExecutionPolicy set as RemoteSigned"
please run (as Administrator):"

```
Set-ExecutionPolicy -ExecutionPolicy "RemoteSigned"
```

After run the script you can set it to `-ExecutionPolicy "Undefined"`

From `https://get.dgraph.io/windows`:
```shell
iwr https://get.dgraph.io/windows -useb | iex
```

Download the script and run locally
```shell
iwr http://get.dgraph.io/windows -useb -outf install.ps1; .\install.ps1
```

## Environment Variables

`$Version="v20.03.1"`: Choose Dgraph’s version manually (default: The latest stable release).

`$acceptLicense="yes"`: Choose Dgraph’s version manually (default: The latest stable release, you can do tag combinations e.g v2.0.0-beta1 or -rc1).

# Compatibility

<!-- Todo: Check Compatibility wioth Windows Subsystem for Linux. -->