#!/bin/sh

_latest="4.15"  # 2021-07-24
_latest="4.16"  # 2022-01-23

_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }
# shellcheck source=/dev/null
. "${_cdir}/../build-scripts/fnc-common-run.sh"

_usage() {
	printf "usage: %s check|build|pack <target> <proxychainsng_version> [<options>]\n" "$0"
	printf "\ntarget:\n"
	printf "\tx86\tx86 32-bit\n"
	printf "\tx64\tx86 64-bit\n"
	printf "\nproxychainsng_version:\n"
	printf "\thead\tlatest development branch\n"
	printf "\tA.BC\tuse specific version, e.g., %s\n" "${_latest}"
	printf "\nexample:\n      %s build x86 %s\n\n" "$0" "${_latest}"
	exit 1
}

[ $# -lt 2 ] && _usage
_action=$1; _target=$2
_arch=$(_get_dockcross_arch "${_target}") || _err "unknown target: ${_target}"
_ver=$3; [ -z "${_ver}" ] && _ver="${_latest}"

shift 2; [ "$#" -gt 0 ] && shift; _opt_req
_opt=""
_name=$(_get_name "${_ver}" "${_opt}")

_pkgs="make git"

_check() {
	docker inspect --type=image "moo/portable-proxychains-ng:${_name}.${_target}" > /dev/null 2>&1
	return $?
}

case $_action in
	check) _check; exit $? ;;
	build)
		_prepare "build-proxychains-ng.sh" proxychains-ng
		_build_docker "dockcross" \
			"moo/portable-proxychains-ng:${_name}.${_target}" \
			"${_arch}" "${_pkgs}" \
			"build-proxychains-ng.sh" "${_ver}" "${_opt}"
		;;
	pack)
		! _check && _err "not built jet."
		cd -- "${_cdir}" || _err "cannot cd to ${_cdir}"
		_fname="proxychains-ng-${_name}.${_target}"
		_tmp="${_cdir}/out/tmp"; rm -rf -- "${_tmp}"; mkdir -p -- "${_tmp}" || _err "mkdir ${_tmp}"
		echo "- dump ${_name}.${_target}"
		docker run --rm \
			-i "moo/portable-proxychains-ng:${_name}.${_target}" \
			tar -czf - -C /cross . > "${_tmp}/dump.tar.gz" || _err "docker+tar"
		tar -xzf "${_tmp}/dump.tar.gz" -C "${_tmp}" || _err "tar"
		_out="${_cdir}/out/${_fname}"; rm -rf -- "${_out}"; mkdir -p -- "${_out}" || _err "mkdir ${_out}"
		echo "- pack ${_fname}"
		for _xdir in "${_tmp}/bin" "${_tmp}/lib"; do
			find "${_xdir}" -type f > "${_tmp}/files.txt"
			while IFS= read -r _xfile; do
				strip --strip-all "${_xfile}" >/dev/null 2>&1
				cp "${_xfile}" "${_out}" || _err "cp"
			done < "${_tmp}/files.txt"
		done
		cp "${_tmp}/proxychains.conf" "${_out}" || _err "cp"
		rm -f -- "${_out}.tar.gz"
		tar -czf "${_out}.tar.gz" -C "${_cdir}/out" "${_fname}" || _err "tar"
		rm -rf -- "${_out}"
		rm -rf -- "${_tmp}"
		;;
	*) _usage ;;
esac

exit 0
