#!/usr/bin/env bash
#
#                  Dgraph Installer Script
#
#   Homepage: https://dgraph.io
#   Requires: bash, curl, tar or unzip
#
# Hello! This is a script that installs Dgraph
# into your PATH (which may require password authorization).
# Use it like this:
#
#	$ curl https://get.dgraph.io | bash
#
# This should work on Mac, Linux, and BSD systems.

set -eE
set -o functrace

DIM='\033[2m'
BOLD='\033[1m'
RED='\033[91;1m'
GREEN='\033[32;1m'
RESET='\033[0m'

acceptLower=$(echo "$ACCEPT_LICENSE" | dd  conv=lcase 2> /dev/null)
systemdLower=$(echo "$INSTALL_IN_SYSTEMD" | dd  conv=lcase 2> /dev/null)
downloadLower=$(echo "$JUST_DOWNLOAD" | dd  conv=lcase 2> /dev/null)

ACCEPT_LICENSE=${acceptLower:-n}
INSTALL_IN_SYSTEMD=${systemdLower:-n}
JUST_DOWNLOAD=${downloadLower:-n}

sudo_cmd=""
argVersion=
platform="$(uname | tr '[:upper:]' '[:lower:]')"

print_instruction() {
    printf '%b\n' "$BOLD$1$RESET"
}

print_step() {
    printf '%b\n' "$DIM$1$RESET"
}

print_error() {
    printf '%b\n' "$RED$1$RESET"
}

print_good() {
    printf '%b\n' "$GREEN$1$RESET"
}

check_license_agreement() {
	curl -s https://raw.githubusercontent.com/dgraph-io/dgraph/master/licenses/DCL.txt
	cat << "EOF"

By downloading Dgraph you agree to the Dgraph Community License (DCL) terms
shown above. An open source (Apache 2.0) version of Dgraph without any
DCL-licensed enterprise features is available by building from the Dgraph
source code. See the source installation instructions for more info:

    https://github.com/dgraph-io/dgraph#install-from-source

EOF
	if [ ! "$ACCEPT_LICENSE" = "y" ]; then
		read -p 'Do you agree to the terms of the Dgraph Community License? [Y/n] ' response < /dev/tty
		[[ "x$response" == "x" || "$response" == [yY] || "$response" == [yY][eE][sS] ]] || return 1
	else
		echo 'Dgraph Community License terms accepted with -y/--accept-license option.'
	fi
}

install_dgraph() {

printf "%b" "$BOLD"
cat << "EOF"
  _____                        _
 |  __ \                      | |
 | |  | | __ _ _ __ __ _ _ __ | |__
 | |  | |/ _` | '__/ _` | '_ \| '_ \
 | |__| | (_| | | | (_| | |_) | | | |
 |_____/ \__, |_|  \__,_| .__/|_| |_|
          __/ |         | |
         |___/          |_|

EOF
printf "%b" "$RESET"

	# Check curl is installed
	if ! hash curl 2>/dev/null; then
		print_error "Could not find curl. Please install curl and try again.";
		exit 1;
	fi
	# Check tar is installed
	if ! hash tar 2>/dev/null; then
		print_error "Could not find tar. Please install tar and try again.";
		exit 1;
	fi

	if [ "$JUST_DOWNLOAD" = "y" ]; then
		install_path="."
	  else

	  install_path="/usr/local/bin"

	  # Check sudo permissions
	  if hash sudo 2>/dev/null; then
		sudo_cmd="sudo"
		echo "Requires sudo permission to install Dgraph binaries to $install_path."
		if ! $sudo_cmd -v; then
			print_error "Need sudo privileges to complete installation."
			exit 1;
		fi
	  fi
		# Create /usr/local/bin directory if it doesn't exist.
		$sudo_cmd mkdir -p $install_path
    fi


	if ! check_license_agreement; then
		print_error 'You must agree to the license terms to install Dgraph.'
		exit 1
	fi

	check_versions(){
		toCompare=$(curl -s https://get.dgraph.io/latest | grep -o "${release_version}" | head -n1)

			if [ "$release_version" == "$toCompare" ]; then
			    return
				else
				print_error "This version doesn't exist or it is a typo (Tip: You need to add \"v\" eg: v22.0.0-RC1-20221003)"
				exit 1
			fi
	}

	if [ -n "${VERSION}" ] || [ -n "${argVersion}" ]; then
	    # Environment variable is preferred over command-line argument
	    release_version="${VERSION:-${argVersion}}"
		check_versions
	    print_step "Selected release version is $release_version."
    else
        release_version=$(curl -s https://get.dgraph.io/latest | grep -o '"tag_name": *"[^"]*' | grep -o '[^"]*$')
	    print_step "Latest release version is $release_version."
    fi

	digest_cmd=""
	if hash shasum 2>/dev/null; then
	  digest_cmd="shasum -a 256"
	elif hash sha256sum 2>/dev/null; then
	  digest_cmd="sha256sum"
	elif hash openssl 2>/dev/null; then
	  digest_cmd="openssl dgst -sha256"
	else
	  print_error "Could not find suitable hashing utility. Please install shasum or sha256sum and try again.";
	  exit 1
	fi

	if [ "$1" == "" ]; then
		tag="$release_version"
	else
		print_error "Invalid argument '$1'."
		exit 1
	fi

	checksum_file="dgraph-checksum-$platform-amd64".sha256
	checksum_link=$( echo https://github.com/dgraph-io/dgraph/releases/download/"$tag"/"$checksum_file")
	print_step "Downloading checksum file for ${tag} build."
	if curl -L --progress-bar "$checksum_link" -o "/tmp/$checksum_file"; then
		print_step "Download complete."
	else
		print_error "Sorry. Binaries not available for your platform. Please compile manually: https://dgraph.io/docs/deploy/#building-from-source"
		echo
		exit 1;
	fi

	if grep -Fxq "$install_path"/dgraph /tmp/"$checksum_file"
	then
		# for versions < 22, the install path is present in the SHA file
		# example file from release v21.03.2 https://github.com/dgraph-io/dgraph/releases/download/v21.03.2/dgraph-checksum-linux-amd64.sha256
		dgraph=$(grep -m 1 "$install_path"/dgraph  /tmp/"$checksum_file" | grep -E -o '[a-zA-Z0-9]{64}')
	else
		# for versions >= 22, the install path is NOT present in the SHA file
		# example file from release v22.0.2 https://github.com/dgraph-io/dgraph/releases/download/v22.0.2/dgraph-checksum-linux-amd64.sha256
		dgraph=$(cat /tmp/"$checksum_file")
	fi

	if [ "$dgraph" == "" ]; then
	     print_error "Sorry, we don't have binaries for this platform. Please build from source."
	     exit 1;
	fi

	print_step "Comparing checksums for dgraph binaries"

	if $digest_cmd $install_path/dgraph &>/dev/null; then
		dgraphsum=$($digest_cmd $install_path/dgraph | grep -E -o '[a-zA-Z0-9]{64}')
	else
		dgraphsum=""
	fi

	if [ "$dgraph" == "$dgraphsum" ]; then
		print_good "You already have Dgraph $tag installed."
	else
		tar_file=dgraph-$platform-amd64".tar.gz"
		dgraph_link="https://github.com/dgraph-io/dgraph/releases/download/$tag/"$tar_file

		# Download and untar Dgraph binaries
		if curl --output /dev/null --silent --head --fail "$dgraph_link"; then
			print_step "Downloading $dgraph_link"
			curl -L --progress-bar "$dgraph_link" -o "/tmp/$tar_file"
			print_good "Download complete."
		else
			print_error "Sorry. There was an issue when downloading $dgraph_link. Binaries not available for your platform. Please compile manually: https://dgraph.io/docs/deploy/#building-from-source"
			echo
			exit 1;
		fi

		print_step "Inflating binaries (password may be required).";
		temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')
		tar -C "$temp_dir" -xzf /tmp/"$tar_file"
		dgraphsum=$($digest_cmd "$temp_dir"/dgraph | awk '{print $1;}')
		if [ "$dgraph" != "$dgraphsum" ]; then
			print_error "Downloaded binaries checksum doesn't match with latest versions checksum"
			exit 1;
		fi

        
	if [ "$JUST_DOWNLOAD" = "y" ]; then
		print_instruction "----------------------------- Dgraph -----------------------------------"
		print_instruction "Downloading badger and dgraph locally only. Please move the binaries to your desired location."
		print_instruction "----------------------------- Dgraph -----------------------------------"
    	else
		# Backup existing dgraph binaries in HOME directory
		if hash dgraph 2>/dev/null; then
			dgraph_path="$(command -v dgraph)"
			dgraph_backup="dgraph_backup_olderversion"
			print_step "Backing up older versions in ~/$dgraph_backup (password may be required)."
			mkdir -p ~/$dgraph_backup
			$sudo_cmd mv $dgraph_path* ~/$dgraph_backup/.
		fi
    fi
        
		$sudo_cmd mv "$temp_dir"/* $install_path/
		rm "/tmp/""$tar_file";
		rm -rf "$temp_dir"

		# Check installation
		if hash dgraph 2>/dev/null; then
			print_good "Dgraph binaries $tag have been installed successfully in $install_path.";
		else
			print_error "Installation failed. Please try again.";
			exit 1;
		fi
	fi

	print_instruction "Please visit https://dgraph.io/docs/get-started for further instructions on usage."
}

addGroup() {
	if id "dgraph" &>/dev/null; then
	    echo 'user found - skipping' 1>&2
	else
	echo 'user not found -  creating one...' 1>&2
	$sudo_cmd groupadd --system dgraph
	$sudo_cmd useradd --system -d /var/lib/dgraph -s /bin/false -g dgraph dgraph
	fi
	true
}

render_template() {
  eval "echo \"$(cat $1)\""
}

 gen() {
  empty=''
  description=$1
  requires=$2
  requiredBy=$3
  cmd=$4
  afterService=$5
  render_template "$tmplTemp/service.tmpl"| $sudo_cmd tee $6 > /dev/null
}

setup_systemD() {

	pathToTemplate="https://raw.githubusercontent.com/dgraph-io/Install-Dgraph/master/contrib"
	systemdPath="/etc/systemd/system"
	dgraphPath="/var/lib/dgraph"
	tmplTemp="/tmp/dgraph"

	$sudo_cmd mkdir -p $dgraphPath
	$sudo_cmd mkdir -p $dgraphPath/{p,w,zw}
	$sudo_cmd mkdir -p /var/log/dgraph
	$sudo_cmd chown -R dgraph:dgraph /var/{lib,log}/dgraph
	$sudo_cmd mkdir -p $tmplTemp

	_getTmpl="$pathToTemplate/service.tmpl"

	$sudo_cmd curl -LJ --progress-bar "$_getTmpl" -o "$tmplTemp/service.tmpl"

	echo "#### Creating dgraph-ui.service ..."

	gen "dgraph.io Web UI" \
		"" \
		"" \
		"dgraph-ratel" \
		"" \
		$systemdPath/dgraph-ui.service

	echo "#### Creating dgraph-alpha.service ..."

	gen "dgraph.io Alpha instance" \
		"Requires=dgraph-zero.service" \
		"" \
		"dgraph alpha --lru_mb 2048 -p /var/lib/dgraph/p -w /var/lib/dgraph/w" \
		"dgraph-zero.service" \
		$systemdPath/dgraph-alpha.service

	echo "#### Creating dgraph-zero.service ..."

	gen "dgraph.io Zero instance" \
		"" \
		"RequiredBy=dgraph-alpha.service" \
		"dgraph zero --wal /var/lib/dgraph/zw" \
		"" \
		$systemdPath/dgraph-zero.service

    $sudo_cmd rm -rf "$tmplTemp"	

	$sudo_cmd systemctl daemon-reload

	$sudo_cmd systemctl enable dgraph-alpha
	$sudo_cmd systemctl start dgraph-alpha

	$sudo_cmd systemctl enable dgraph-ui
	$sudo_cmd systemctl start dgraph-ui

	true

}

function exit_error {
  if [ "$?" -ne 0 ]; then
    print_error "There was some problem while installing Dgraph. Please share the output of this script with us on https://discuss.dgraph.io so that we can resolve the issue for you."
  fi
}

verify_system() {
    if [ -x /sbin/openrc-run ]; then
        HAS_OPENRC=true
        print_error "Sorry we don't support OpenRC for now."
		print_good "But you can install Dgraph, remove the flag and try again."
        exit 1
    fi
    if hash systemctl 2>/dev/null; then
		print_good "Habemus SYSTEMD."
		INSTALL_IN_SYSTEMD="y"
        return 0
    fi
    print_error "Systemd was not found."
	print_good "Wrong OS?? you still can install Dgraph(Linux only), remove the flag and try again or build from the source."
    return 1
}

print_usage() {
	echo "Usage:"
	echo "	-v='' | --version='v22.0.0' 	: Choose Dgraph's version manually."
	echo "	-d    | --download             	: Download the binary to the current path."
	echo "	-s    | --systemd             	: Install Dgraph as a service."
	echo "	-y    | --accept-license	    : Automatically agree to the terms of the Dgraph Community License."
}

REGX=$(echo $@ | sed -n '/v/p')

old_OS() {
    if [[ ${VERSION} ]] || [[ ${argVersion} ]]; then
        echo 'Manually configured version. Hope you know that we only have built assets for versions below v20.11.3'
        print_good "Continuing wait 3 sec...".
        sleep 3
        return 0
    else
        read -p 'Do you wish to install an older version? The version v20.11.3 - (Tenacious T’Challa - 3 | Mar 31 2021)  [Y/n] ' response < /dev/tty
        [[ "x$response" == "x" || "$response" == [yY] || "$response" == [yY][eE][sS] ]] || return 1
        argVersion="v20.11.3"
    fi
}
check_platform() {
if  [[  -z $REGX  &&  "$platform" == "darwin" ]]; then
	     print_error "Sorry, we don't have new binaries for this platform since Jun 18 2021. Please build from source."
		 print_good  "if you wanna install some old version. You can still install it if you use the flag -v plus the desired version."
		 print_good  "Note that it will fail if you choose the wrong version for your OS(unsupported OS)"
		 old_OS
	fi
}

failure() {
  local lineno=$1
  local msg=$2
  print_error "Failed at $lineno: $msg"
}

trap 'failure ${LINENO} "$BASH_COMMAND" ${exit_error}' ERR
trap exit_error EXIT

for f in "$@"; do
	case $f in
		'-y'|'--accept-license')
			ACCEPT_LICENSE=y
			;;
		'-s'|'--systemd')
			verify_system
			;;
		'-v='*|'--version='*)
			argVersion=${f#*=}
			;;
		'-d'|'--download')
			JUST_DOWNLOAD=y
			;;
		'-h'|'--help')
			print_usage
			exit 0
			;;
		*)
			print_error "unknown option $1"
			print_usage
			exit 1
			;;
	esac
	shift
done

check_platform

install_dgraph "$@"

if [ "$INSTALL_IN_SYSTEMD" = "y" ]; then
	echo "Systemd installation was requested."
	addGroup && setup_systemD
fi
