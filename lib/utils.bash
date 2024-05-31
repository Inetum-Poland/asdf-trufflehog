#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s nocasematch

GH_REPO="https://github.com/trufflesecurity/trufflehog"
TOOL_NAME="trufflehog"
TOOL_TEST="trufflehog --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if trufflehog is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

platform=""
case "$(uname -s)" in
	darwin*) platform="darwin" ;;
	linux*) platform="linux" ;;
	# freebsd*) platform="freebsd" ;;
	# netbsd*) platform="netbsd" ;;
	# openbsd*) platform="openbsd" ;;
	*) fail "Unsupported platform" ;;
esac

architecture=""
case "$(uname -m)" in
	aarch64* | arm64) architecture="arm64" ;;
	x86_64*) architecture="amd64" ;;
	# armv5* | armv6* | armv7*) architecture="arm" ;;
	# i686*) architecture="386" ;;
	# ppc64le*) architecture="ppc64le" ;;
	# ppc64*) architecture="ppc64" ;;
	# ppc*) architecture="ppc" ;;
	# mipsel*) architecture="mipsle" ;;
	# mips*) architecture="mips" ;;
	*) fail "Unsupported architecture" ;;
esac

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	# Change this function if trufflehog has other means of determining installable versions.
	list_github_tags
}

# trufflehog_3.77.0_darwin_amd64.tar.gz
# trufflehog_3.77.0_darwin_arm64.tar.gz
# trufflehog_3.77.0_linux_amd64.tar.gz
# trufflehog_3.77.0_linux_arm64.tar.gz
download_release() {
	local url
	local version="$1"
	local release_file="${TOOL_NAME}_${ASDF_INSTALL_VERSION}_${platform}_${architecture}.tar.gz"
	local checksum_release_file="${TOOL_NAME}_${version}_checksums.txt"

	# /releases/download/v3.77.0/trufflehog_3.77.0_darwin_arm64.tar.gz
	url="${GH_REPO}/releases/download/v${version}/${release_file}"

	# /releases/download/v3.77.0/trufflehog_3.77.0_checksums.txt
	sha_url="${GH_REPO}/releases/download/v${version}/${checksum_release_file}"

	echo "* Downloading ${TOOL_NAME} release ${version}..."
	curl "${curl_opts[@]}" -o "${ASDF_DOWNLOAD_PATH}/${release_file}" -C - "$url" || fail "Could not download ${url}"

	echo "* Downloading ${TOOL_NAME} release checksum ${version}..."
	curl "${curl_opts[@]}" -o "${ASDF_DOWNLOAD_PATH}/${checksum_release_file}" -C - "${sha_url}" || fail "Could not download ${sha_url}"

	pushd "${ASDF_DOWNLOAD_PATH}"
	grep "${release_file}" "${checksum_release_file}" | sha256sum -c || fail "Could not verify checksum for $filename"
	rm "${checksum_release_file}"
	popd
}

unpack_release() {
	local install_path="$1"
	local release_file="${TOOL_NAME}_${ASDF_INSTALL_VERSION}_${platform}_${architecture}.tar.gz"

	tar -xzf "${ASDF_DOWNLOAD_PATH}/${release_file}" -C "${install_path}" --strip-components=0 || fail "Could not extract ${release_file}"

	# Remove the tar.gz file since we don't need to keep it
	rm "${ASDF_DOWNLOAD_PATH}/${release_file}"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
