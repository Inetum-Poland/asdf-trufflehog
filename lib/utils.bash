#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s nocasematch

GH_REPO="https://github.com/trufflesecurity/trufflehog"
TOOL_NAME="trufflehog"
TOOL_TEST="trufflehog --version"

# PS4='+ ${BASH_SOURCE}:${LINENO}:(${FUNCNAME[0]:+${FUNCNAME[0]}(): }) '
# set -x

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

show_latest_version() {
	# curl of REPO/releases/latest is expected to be a 302 to another URL
	# when no releases redirect_url="REPO/releases"
	# when there are releases redirect_url="REPO/releases/tag/v<VERSION>"
	curl_opts=(-sI)
	redirect_url=$(curl "${curl_opts[@]}" "$GH_REPO/releases/latest" | sed -n -e "s|^location: *||p" | sed -n -e "s|\r||p")
	version=

	printf "redirect url: %s\n" "$redirect_url" >&2

	if [[ "$redirect_url" == "$GH_REPO/releases" ]]; then
		version="$(list_all_versions | sort_versions | tail -n1 | xargs echo)"
	else
		version="$(printf "%s\n" "$redirect_url" | sed 's|.*/tag/v\{0,1\}||')"
	fi

	printf "%s\n" "$version"
}

# trufflehog_3.77.0_darwin_amd64.tar.gz
# trufflehog_3.77.0_darwin_arm64.tar.gz
# trufflehog_3.77.0_linux_amd64.tar.gz
# trufflehog_3.77.0_linux_arm64.tar.gz
download_release() {
	local url
	local release_file="${TOOL_NAME}_${ASDF_INSTALL_VERSION}_${platform}_${architecture}.tar.gz"
	local checksum_release_file="${TOOL_NAME}_${ASDF_INSTALL_VERSION}_checksums.txt"

	mkdir -p "${ASDF_DOWNLOAD_PATH}"

	# /releases/download/v3.77.0/trufflehog_3.77.0_darwin_arm64.tar.gz
	url="${GH_REPO}/releases/download/v${ASDF_INSTALL_VERSION}/${release_file}"
	echo "* Downloading ${TOOL_NAME} release ${ASDF_INSTALL_VERSION}..."
	curl "${curl_opts[@]}" -o "${ASDF_DOWNLOAD_PATH}/${release_file}" -C - "$url" || fail "Could not download ${url}"

	if command -v sha256sum; then
		# /releases/download/v3.77.0/trufflehog_3.77.0_checksums.txt
		sha_url="${GH_REPO}/releases/download/v${ASDF_INSTALL_VERSION}/${checksum_release_file}"
		echo "* Downloading ${TOOL_NAME} release checksum ${ASDF_INSTALL_VERSION}..."
		curl "${curl_opts[@]}" -o "${ASDF_DOWNLOAD_PATH}/${checksum_release_file}" -C - "${sha_url}" || fail "Could not download ${sha_url}"

		pushd "${ASDF_DOWNLOAD_PATH}" >/dev/null
		grep "${release_file}" "${checksum_release_file}" | sha256sum -c || fail "Could not verify checksum for $release_file"
		rm "${checksum_release_file}"
		popd >/dev/null
	fi
}

unpack_release() {
	local release_file="${TOOL_NAME}_${ASDF_INSTALL_VERSION}_${platform}_${architecture}.tar.gz"

	tar -xzf "${ASDF_DOWNLOAD_PATH}/${release_file}" -C "${ASDF_DOWNLOAD_PATH}" --strip-components=0 || fail "Could not extract ${release_file}"

	# Remove the tar.gz file since we don't need to keep it
	rm "${ASDF_DOWNLOAD_PATH}/${release_file}"
}

install_version() {
	if [ "${ASDF_INSTALL_TYPE}" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "${ASDF_INSTALL_PATH%/bin}/bin"
		cp -r "${ASDF_DOWNLOAD_PATH}/${TOOL_NAME}" "${ASDF_INSTALL_PATH%/bin}/bin"

		local tool_cmd
		tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)"
		test -x "${ASDF_INSTALL_PATH%/bin}/bin/$tool_cmd" || fail "Expected ${ASDF_INSTALL_PATH%/bin}/bin/${tool_cmd} to be executable."

		echo "${TOOL_NAME} ${ASDF_INSTALL_VERSION} installation was successful!"
	) || (
		rm -rf "${ASDF_INSTALL_PATH%/bin:?}/bin"
		fail "An error occurred while installing ${TOOL_NAME} ${ASDF_INSTALL_VERSION}."
	)
}
