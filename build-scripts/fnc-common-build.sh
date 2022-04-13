#!/bin/sh

_err() { echo "err: $1" >&2 && exit 1; }

_cd() { cd -- "$1" || _err "directory $1 does not exist"; }

_has_opt() { echo "$1" | tr '|' '\n' | grep -q "^${2}$"; return $?; }

_msg() {
	printf '<%*s' 45 '' | sed 's/ /=/g'
	echo " $1"
}

_get_fetch() {
	_ua="wget"
	command -v fetch >/dev/null 2>&1 && echo "fetch -q --user-agent='${_ua}' -o " && return 0
	command -v wget  >/dev/null 2>&1 && echo "wget -q -U '${_ua}' -O " && return 0
	command -v curl  >/dev/null 2>&1 && echo "curl -Ls -A '${_ua}' -o " && return 0
	return 1
}

_fetch_and_extract() {  # 1 - name, 2 - version, 3 - url, 4 - ext
	[ -z "$2" ] && _err "no $1 version defined."
	_fetch=$(_get_fetch) || _err "no download utility (fetch/curl/wget) found."
	_cd "${BUILD_DIR}"
	case $1 in
		*_) _fn="$1$2" ;;
		*) _fn="$1-$2" ;;
	esac
	_ext="tar.gz"; [ -n "$4" ] && _ext="$4"
	${_fetch} "${_fn}.${_ext}" "${3}${_fn}.${_ext}" || _err "fetch failed"
	case "${_ext}" in
		tar.gz) tar -xzf "${_fn}.${_ext}" || _err "tar" ;;
		tar.bz2) tar -xjf "${_fn}.${_ext}" || _err "tar" ;;
		*) _err "unknown extension: ${_ext}" ;;
	esac
	_cd "${_fn}"
}

_get_configure_host() {
        case "${BUILD_ARCH}" in
                *x86|i486*|i586*|i686*) echo "i486-linux" ;;
                *x64|x86_64*) echo "x86_64-linux" ;;
                *) _err "unknown arch: ${BUILD_ARCH}" ;;
        esac
}

_done() {
	# FIX: https://github.com/moby/moby/issues/34645
	chown -R root:root -- "${BUILD_DIR}/out"
	exit 0
}
