# Dgraph Install Scripts

This repository is home to the installation scripts that you find at `https://get.dgraph.io` and others.

Works for:

* :white_check_mark: Ubuntu 16.04 and above 
* :x: macOS Sierra and above
* :x: Windows 10 and above
* :x: Windows Server 2016 above

<!-- Todo: Add Windows Version with Powershell version tested. -->
<!-- Todo: Add Systemd references. -->

# Install Dgraph on Linux and macOS

<!-- Todo: Add Brew formula here. -->

> macOS is no longer supported (for now), you can only install old versions.

### Using Shell

From `https://get.dgraph.io`

Download latest:
```shell
curl https://get.dgraph.io -sSf | bash
```

Download latest and install as Systemd services (just Linux):

```shell
curl https://get.dgraph.io -sSf | bash -s -- --systemd
```

With Environment Variables:

```shell
curl https://get.dgraph.io -sSf | VERSION=v20.03.1-beta1 bash
```

## Flags

Add `-s --` before the flags.

>`-y | --accept-license`: Automatically agree to the terms of the Dgraph Community License (default: “n”).

>`-s | --systemd`: Automatically create Dgraph’s installation as Systemd services (default: “n”).

>`-v | --version`: Choose Dgraph’s version manually (default: The latest stable release, you can do tag combinations e.g v20.03.1-beta1 or -rc1).


## Environment Variables

>`ACCEPT_LICENSE`: Automatically agree to the terms of the Dgraph Community License (default: “n”).

>`INSTALL_IN_SYSTEMD`: Automatically create Dgraph’s installation as Systemd services (default: “n”).

>`VERSION`: Choose Dgraph’s version manually (default: The latest stable release).


# Install Dgraph on Windows

> No longer supported (for now).

### Using Powershell

This script needs to be executed with ExecutionPolicy set as RemoteSigned"
please run (as Administrator):"

```
Set-ExecutionPolicy -ExecutionPolicy "RemoteSigned"
```

After run the script you can set it to `-ExecutionPolicy "Undefined"`

From `https://get.dgraph.io/windows`

Download latest:

```shell
iwr https://get.dgraph.io/windows -useb | iex
```

With Environment Variables:

```shell
$Version="v20.03.1"; $acceptLicense="yes"; iwr http://get.dgraph.io/windows -useb | iex
```

Download the script and run locally

```shell
iwr http://get.dgraph.io/windows -useb -outf install.ps1; .\install.ps1
```

Run locally with flags

```shell
iwr http://get.dgraph.io/windows -useb -outf install.ps1; .\install.ps1 -version v20.03.1 -acceptLicense yes
```

## Flags

>`-acceptLicense`: Automatically agree to the terms of the Dgraph Community License (default: ask).

>`-version`: Choose Dgraph’s version manually (default: The latest stable release, you can do tag combinations e.g v20.03.1-beta1 or -rc1).

## Environment Variables

>`$Version="v20.03.1"`: Choose Dgraph’s version manually (default: The latest stable release).

>`$acceptLicense="yes"`: Choose Dgraph’s version manually (default: The latest stable release, you can do tag combinations e.g v2.0.0-beta1 or -rc1).

## Compatibility

This Scrip works on Windows 10, some Windows containers and Windows Server 2016 only.

<!-- Todo: Check Compatibility with Windows Subsystem for Linux. -->
