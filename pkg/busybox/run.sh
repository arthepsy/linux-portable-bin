#!/bin/sh

_latest="1.35.0"   # 2021-12-30
_latest="1.36.0"   # 2023-01-03
_latest="1.36.1"   # 2023-05-19

_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }
# shellcheck source=/dev/null
. "${_cdir}/../build-scripts/fnc-common-run.sh"

_usage() {
	printf "usage: %s check|build|pack|debug <target> <busybox_version> [<options>]\n" "$0"
	printf "\ntarget:\n"
	printf "\tx86\tx86 32-bit (musl)\n"
	printf "\tx64\tx86 64-bit (musl)\n"
	printf "\nbusybox_version:\n"
	printf "\tA.B.C\tuse specific version, e.g., %s\n" "${_latest}"
	printf "\nexample:\n      %s build x64 %s\n\n" "$0" "${_latest}"
	exit 1
}

[ $# -lt 2 ] && _usage
_action=$1; _target=$2
_arch=$(_get_musl_arch "${_target}") || _err "unknown target: ${_target}"
_ver=$3; [ -z "${_ver}" ] && _ver="${_latest}"

shift 2; [ "$#" -gt 0 ] && shift; _opt_req
_opt=""
_name=$(_get_name "${_ver}" "${_opt}")

_pkgs="make sed musl-dev gcc git patch file"

_check() {
	docker inspect --type=image "moo/static-busybox:${_name}.${_target}" > /dev/null 2>&1
	return $?
}

_debug=""
if [ "${_action}" = "debug" ]; then
	_action="build"
	_debug="debug"
fi

case $_action in
	check) _check; exit $? ;;
	build)
		_prepare "build-busybox.sh" busybox
		_build_docker "musl" \
			"moo/static-busybox:${_name}.${_target}" \
			"${_arch}" "${_pkgs}" \
			"build-busybox.sh" "${_ver}" "${_opt}" "${_debug}"
		;;
	pack)
		! _check && _err "not built yet."
		cd -- "${_cdir}" || _err "cannot cd to ${_cdir}"
		_fname="busybox-${_name}.${_target}"
		_tmp="${_cdir}/out/tmp"; rm -rf -- "${_tmp}"; mkdir -p -- "${_tmp}" || _err "mkdir ${_tmp}"
		echo "- dump ${_fname}"
		docker run --rm \
			-i "moo/static-busybox:${_name}.${_target}" \
			tar -czf - -C /cross . > "${_tmp}/dump.tar.gz" || _err "docker+tar"
		tar -xzf "${_tmp}/dump.tar.gz" -C "${_tmp}" || _err "tar"
		_out="${_cdir}/out/${_fname}"; rm -rf -- "${_out}"; mkdir -p -- "${_out}" || _err "mkdir ${_out}"
		echo "- strip ${_fname}"
		_docker_strip "${_tmp}" "busybox"
		echo "- pack ${_fname}"
		cp "${_tmp}/busybox" "${_out}" || _err "cp"
		rm -f -- "${_out}.tar.gz"
		tar -czf "${_out}.tar.gz" -C "${_cdir}/out" "${_fname}" || _err "tar"
		rm -rf -- "${_out}"
		rm -rf -- "${_tmp}"
		;;
	*) _usage ;;
esac

exit 0
