# vim: filetype=sh

_fallback() { printf "warn: %s\n" "$1" >&2; exec ash; }

_is_standalone_shell() {
	if [ -n "${BB_ASH_VERSION:-}" ]; then
		if [ "$(PATH=/usr/sbin:/usr/bin:/sbin:/bin type cat 2>/dev/null)" = "cat is cat" ]; then
			return 0
		fi
	fi
	return 1
}

_detect_busybox() {
	[ -n "${_BB_EXE:-}" ] && return 0
	_BB_EXE=""
	_CSH=""
	case "$(uname -s)" in
		Linux) _CSH="$(exec 2>/dev/null; readlink "/proc/$$/exe")" ;;
		FreeBSD) _CSH="$(exec 2>/dev/null; procstat binary $$ | tail -1 | sed -e 's#.* ##g')" ;;
		*) _fallback "unknown OS: $(uname -s)" ;;
	esac
	case "${_CSH}" in
		*/busybox)
			_BB_EXE="${_CSH}"
			unset _CSH
			return 0 
			;;
		*) _fallback "unknown shell: ${_CSH}" ;;
	esac
	unset _CSH
	return 1
}

_create_temp() {
	[ -n "${_TMP:-}" ] && return 0
	_TMP="$(mktemp -d 2>/dev/null)"; _ec=$?
	if [ ${_ec} -ne 0 ]; then
		_fallback 'cannot create temp directory'
	fi
	unset _ec
	return 0
}

_remove_temp() {
	[ -z "${_TMP:-}" ] && return 0
	(sleep 2; rm -rf -- "${_TMP}" 2>/dev/null) &
}


if _is_standalone_shell; then
	if [ $# -eq 0 ]; then
		exec ash
		return 0
	fi
else
	_detect_busybox || _fallback 'could not detect busybox'
	_create_temp
	"${_BB_EXE}" --list | while IFS= read -r _cmd; do
		printf 'alias %s="%s %s"\n' "${_cmd}" "${_BB_EXE}" "${_cmd}" >> "${_TMP}/ENV"
	done
fi
while [ $# -gt 0 ]; do
	_detect_busybox || _fallback 'could not detect busybox'
	_create_temp
	if [ -z "${_BB_DIR}" ]; then
		_BB_DIR="$(dirname "${_BB_EXE}")"
	fi
	case "$1" in
		-*) break ;;
		*) ;;
	esac
	_cmd="$1"
	if [ -x "${_BB_DIR}/${_cmd}" ]; then
		printf 'alias %s="%s/%s"\n' "${_cmd}" "${_BB_DIR}" "${_cmd}" >> "${_TMP}/ENV"
	fi
	unset _cmd
	shift
done
unset _BB_DIR
unset _BB_EXE
_remove_temp &
ENV="${_TMP}/ENV" exec ash "$@"

