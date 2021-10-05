#!/bin/sh

_latest="1.7.4.1"  # 2021-01-10

_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }
# shellcheck source=/dev/null
. "${_cdir}/../build-scripts/fnc-common-run.sh"


_usage() {
	printf "usage: %s check|build|pack <target> <socat_version> [<options>]\n" "$0"
	printf "\ntarget:\n"
	printf "\tx86\tx86 32-bit (musl)\n"
	printf "\tx64\tx86 64-bit (musl)\n"
	printf "\noptions:\n"
	printf "\tssl     \tuse SSL\n"
	printf "\tweak-ssl\tuse SSL (with weak ciphers)\n"
	printf "\nexample:\n      %s build x86 %s\n\n" "$0" "${_latest}"
	exit 1
}

[ $# -lt 2 ] && _usage
_action=$1; _target=$2
_arch=$(_get_musl_arch "${_target}") || _err "unknown target: ${_target}"
_ver=$3; [ -z "${_ver}" ] && _ver="${_latest}"

shift 2; [ "$#" -gt 0 ] && shift; _opt_req
_opt=$(_get_opt "ssl|weak-ssl" "$@") || _err "${_opt}"
_has_opt "${_opt}" "ssl" && _has_opt "${_opt}" "weak-ssl" && _usage
_name=$(_get_name "${_ver}" "${_opt}")

_pkgs="make perl"

_check() {
	docker inspect --type=image "moo/static-socat:${_name}.${_target}" > /dev/null 2>&1
	return $?
}

case $_action in
	check) _check; exit $? ;;
	build)
		_prepare "build-socat.sh" ncurses readline tcp_wrappers zlib openssl socat
		_build_docker "musl" \
			"moo/static-socat:${_name}.${_target}" \
			"${_arch}" "${_pkgs}" \
			"build-socat.sh" "${_ver}" "${_opt}"
		;;
	pack)
		! _check && _err "not built jet."
		cd -- "${_cdir}" || _err "cannot cd to ${_cdir}"
		_fname="socat-${_name}.${_target}"
		_tmp="${_cdir}/out/tmp"; rm -rf -- "${_tmp}"; mkdir -p -- "${_tmp}" || _err "mkdir ${_tmp}"
		echo "- dump ${_fname}"
		docker run --rm \
			-i "moo/static-socat:${_name}.${_target}" \
			tar -czf - -C /cross . > "${_tmp}/dump.tar.gz" || _err "docker+tar"
		tar -xzf "${_tmp}/dump.tar.gz" -C "${_tmp}" || _err "tar"
		_out="${_cdir}/out/${_fname}"; rm -rf -- "${_out}"; mkdir -p -- "${_out}" || _err "mkdir ${_out}"
		echo "- pack ${_fname}"
		for _f in socat procan filan; do
			strip --strip-all "${_tmp}/bin/${_f}" > /dev/null 2>&1
			mv "${_tmp}/bin/${_f}" "${_out}" || _err "mv"
		done
		mv "${_tmp}/share/man/man1/socat.1" "${_out}" || _err "mv"
		rm -f -- "${_out}.tar.gz"
		tar -czf "${_out}.tar.gz" -C "${_cdir}/out" "${_fname}" || _err "tar"
		rm -rf -- "${_out}"
		rm -rf -- "${_tmp}"
		;;
	*) _usage ;;
esac

exit 0
