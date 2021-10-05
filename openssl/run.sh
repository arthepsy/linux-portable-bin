#!/bin/sh

_latest="1.1.1l"  # 2021-08-24

_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }
# shellcheck source=/dev/null
. "${_cdir}/../build-scripts/fnc-common-run.sh"

_usage() {
        printf "usage: %s check|build|pack <target> <openssl_version> [<options>]\n" "$0"
        printf "\ntarget:\n"
        printf "\tx86\tx86 32-bit (musl)\n"
        printf "\tx64\tx86 64-bit (musl)\n"
        printf "\nopenssl_version:\n"
	printf "\t1.0.2-bad\tuse openssl-1.0.2.bad (from testssl.sh)\n"
	printf "\tA.B.Cx      \tuse specific version, e.g., %s\n" "${_latest}"
	printf "\noptions:\n"
        printf "\tzlib    \twith zlib\n"
        printf "\tweak-ssl\twith weak ciphers\n"
        printf "\nexample:\n      %s build x86 %s\n\n" "$0" "${_latest}"
        exit 1
}

[ $# -lt 2 ] && _usage
_action=$1; _target=$2
_arch=$(_get_musl_arch "${_target}") || _err "unknown target: ${_target}"
_ver=$3; [ -z "${_ver}" ] && _ver="${_latest}"

shift 2; [ "$#" -gt 0 ] && shift; _opt_req
_opt=$(_get_opt "zlib|weak-ssl" "$@") || _err "${_opt}"
_name=$(_get_name "${_ver}" "${_opt}")

_pkgs="make perl"
[ "${_ver}" = "1.0.2-bad" ] && _pkgs="${_pkgs} git"

_check() {
	docker inspect --type=image "moo/static-openssl:${_name}.${_target}" > /dev/null 2>&1
	return $?
}

case "${_action}" in
	check) _check; exit $? ;;
	build)
		_prepare "build-openssl.sh" zlib openssl
		_build_docker "musl" \
			"moo/static-openssl:${_name}.${_target}" \
			"${_arch}" "${_pkgs}" \
			"build-openssl.sh" "${_ver}" "${_opt}"
		;;
	pack)
		! _check && _err "not built jet."
		cd -- "${_cdir}" || _err "cannot cd to ${_cdir}"
                _fname="openssl-${_name}.${_target}"
		_tmp="${_cdir}/out/tmp"; rm -rf -- "${_tmp}"; mkdir -p -- "${_tmp}" || _err "mkdir ${_tmp}"
		echo "- dump ${_fname}"
		docker run --rm \
			-i "moo/static-openssl:${_name}.${_target}" \
			tar -czf - -C /cross . > "${_tmp}/dump.tar.gz" || _err "docker+tar"
		_out="${_cdir}/out/${_fname}"; rm -rf -- "${_out}"; mkdir -p -- "${_out}" || _err "mkdir ${_out}"
		tar -xzf "${_tmp}/dump.tar.gz" -C "${_out}" || _err "tar"
		echo "- pack ${_fname}"
		for _f in openssl c_rehash; do
                        strip --strip-all "${_out}/bin/${_f}" > /dev/null 2>&1
                done
		rm -f -- "${_out}.tar.gz"
		tar -czf "${_out}.tar.gz" -C "${_cdir}/out" "${_fname}" || _err "tar"
		rm -rf -- "${_out}"
		rm -rf -- "${_tmp}"
		;;
	*) _usage ;;
esac

exit 0
