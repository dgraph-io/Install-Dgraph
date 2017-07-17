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

set -e

BLACK='\033[30;1m'
RED='\033[91;1m'
GREEN='\033[32;1m'
RESET='\033[0m'
WHITE='\033[97;1m'

print_instruction() {
    printf "$WHITE$1$RESET\n"
}

print_step() {
    printf "$BLACK$1$RESET\n"
}

print_error() {
    printf "$RED$1$RESET\n"
}

print_good() {
    printf "$GREEN$1$RESET\n"
}

install_dgraph() {

printf $BLACK
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
printf $RESET

	# Check curl is installed
	if ! hash curl 2>/dev/null; then
		print_error "Could not find curl. Please install curl and try again.";
		exit 1;
	fi

	sudo_cmd=""
	if hash sudo 2>/dev/null; then
		sudo_cmd="sudo"
	fi

	install_path="/usr/local/bin"

	release_version="$(curl -s https://api.github.com/repos/dgraph-io/dgraph/releases/latest | grep "tag_name" | awk '{print $2}' | tr -dc '[:alnum:]-.\n\r' | head -n1)"
	print_step "Latest release version is $release_version."

	platform="$(uname | tr '[:upper:]' '[:lower:]')"

	digest_cmd=""
	if hash shasum 2>/dev/null; then
	  digest_cmd="shasum -a 256"
	elif hash sha256sum 2>/dev/null; then
	  digest_cmd="sha256sum"
	else
	  print_error "Could not find suitable hashing utility. Please install shasum or sha256sum and try again.";
	  exit 1
	fi

	checksum_file="dgraph-checksum-$platform-amd64-$release_version".sha256
	checksum_link="https://github.com/dgraph-io/dgraph/releases/download/"$release_version"/"$checksum_file
	print_step "Downloading checksum file."
	if curl -L --progress-bar "$checksum_link" -o "/tmp/$checksum_file"; then
		print_step "Download complete."
	else
		print_error "Sorry. Binaries not available for your platform. Please compile manually: https://docs.dgraph.io"
		echo
		exit 1;
	fi

	dgraph=$(grep -m 1 /usr/local/bin/dgraph  /tmp/$checksum_file | awk '{print $1;}')
	dgraphloader=$(grep -m 1 /usr/local/bin/dgraphloader  /tmp/$checksum_file | awk '{print $1;}')

	print_step "Comparing checksums for dgraph binaries"

	if $digest_cmd /usr/local/bin/dgraph &>/dev/null && $digest_cmd /usr/local/bin/dgraphloader &>/dev/null; then
		dgraphsum=$($digest_cmd /usr/local/bin/dgraph | awk '{print $1;}')
		dgraphloadersum=$($digest_cmd /usr/local/bin/dgraphloader | awk '{print $1;}')
	else
		dgraphsum=""
		dgraphloadersum=""
	fi

	if [ "$dgraph" == "$dgraphsum" ] && [ "$dgraphloader" == "$dgraphloadersum" ]; then
		print_good "You already have Dgraph $release_version installed."
	else
		tar_file=dgraph-$platform-amd64-$release_version".tar.gz"
		dgraph_link="https://github.com/dgraph-io/dgraph/releases/download/"$release_version"/"$tar_file

		# Backup existing dgraph binaries in HOME directory
		if hash dgraph 2>/dev/null; then
			dgraph_path="$(which dgraph)"
			dgraph_backup="dgraph_backup_olderversion"
			print_step "Backing up older versions in ~/$dgraph_backup (password may be required)."
			mkdir -p ~/$dgraph_backup
			$sudo_cmd mv $dgraph_path* ~/$dgraph_backup/.
		fi

		# Download and untar Dgraph binaries
		if curl --output /dev/null --silent --head --fail "$dgraph_link"; then
			print_step "Downloading $dgraph_link"
			curl -L --progress-bar "$dgraph_link" -o "/tmp/$tar_file"
			print_good "Download complete."
		else
			print_error "Sorry. Binaries not available for your platform. Please compile manually: https://docs.dgraph.io";
			echo
			exit 1;
		fi

		print_step "Inflating binaries (password may be required).";
		$sudo_cmd tar -C /usr/local/bin -xzf /tmp/$tar_file --strip-components=1;
		rm "/tmp/"$tar_file;

		# Check installation
		if hash dgraph 2>/dev/null; then
			print_good "Dgraph binaries $release_version have been installed successfully in /usr/local/bin.";
		else
			print_error "Installation failed. Please try again.";
			exit 1;
		fi
	fi

	assets=$(grep -m 1 assets.tar.gz  /tmp/$checksum_file | awk '{print $1;}')

	assetsFile="assets.tar.gz"
	assetsTarLoc="/usr/local/share/dgraph/assets.tar.gz"
	assetsLoc="/usr/local/share/dgraph/assets"
	if $digest_cmd $assetsTarLoc &>/dev/null; then
		assetsSum=$($digest_cmd $assetsTarLoc | awk '{print $1;}')
	else
		assetsSum=""
	fi

	if [ "$assets" == "$assetsSum" ]; then
		print_good "You have the latest assets files."
	else
		if [ -d $assetsLoc ] ; then
			$sudo_cmd rm -r $assetsLoc
		fi
		print_step "Downloading assets.";
		curl -L --progress-bar https://github.com/dgraph-io/dgraph/releases/download/$release_version/$assetsFile -o /tmp/$assetsFile;
		$sudo_cmd mkdir -p /usr/local/share/dgraph /usr/local/share/dgraph/assets
		$sudo_cmd mv /tmp/$assetsFile /usr/local/share/dgraph
		$sudo_cmd tar -xzf $assetsTarLoc -C /usr/local/share/dgraph/assets
		print_good "Assets have been downloaded and put in /usr/local/share/dgraph.";
	fi

	print_instruction "Please visit https://docs.dgraph.io/get-started for further instructions on usage."
}

function exit_error {
  if [ "$?" -ne 0 ]; then
    print_error "There was some problem while installing Dgraph. Please share the output of this script with us on https://dgraph.slack.com or https://discuss.dgraph.io so that we can resolve the issue for you."
  fi
}

trap exit_error EXIT
install_dgraph "$@"
