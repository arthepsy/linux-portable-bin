#!/bin/sh

_latest="7.80"  # 2019-08-13

_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }
# shellcheck source=/dev/null
. "${_cdir}/../build-scripts/fnc-common-run.sh"

_usage() {
	printf "usage: %s check|build|pack <target> <nmap_version> [<options>]\n" "$0"
	printf "       %s fetch-vulners\n" "$0"
	printf "\ntarget:\n"
	printf "\tx86\tx86 32-bit (musl)\n"
	printf "\tx64\tx86 64-bit (musl)\n"
	printf "\nnmap_version:\n"
	printf "\thead\tlatest development branch\n"
	printf "\tA.BC\tuse specific version, e.g., %s\n" "${_latest}"
	printf "\noptions:\n"
	printf "\tbad-ssl \tuse openssl-1.0.2.bad (from testssl.sh)\n"
	printf "\tweak-ssl\tuse openssl with weak ciphers\n"
	printf "\nexample:\n      %s build x86 %s\n\n" "$0" "${_latest}"
	exit 1
}

_fetch_vulners() {
	command -v git >/dev/null 2>&1 || _err "git not available."
	echo "- clone nmap-vulners"
	cd -- "${_cdir}/files" || _err "cannot cd to ${_cdir}/files"
	rm -rf -- ./nmap-vulners.git/ ./nmap-vulners/
	git clone -q --depth=1 "https://github.com/vulnersCom/nmap-vulners.git" nmap-vulners.git || _err "git"
	mkdir -p -- ./nmap-vulners/ || _err "mkdir"
	mv ./nmap-vulners.git/vulners.nse ./nmap-vulners/ || _err "mv"
	mv ./nmap-vulners.git/http-vulners-regex.nse ./nmap-vulners/ || _err "mv"
	mv ./nmap-vulners.git/http-vulners-regex.json ./nmap-vulners/ || _err "mv"
	mv ./nmap-vulners.git/http-vulners-paths.txt ./nmap-vulners/ || _err "mv"
	rm -rf -- ./nmap-vulners.git/
	exit 0
}

[ "$1" = "fetch-vulners" ] && _fetch_vulners
[ $# -lt 2 ] && _usage
_action=$1; _target=$2
_arch=$(_get_musl_arch "${_target}") || _err "unknown target: ${_target}"
_ver=$3; [ -z "${_ver}" ] && _ver="${_latest}"

shift 2; shift; _opt_req
_opt=$(_get_opt "bad-ssl|weak-ssl" "$@") || _err "${_opt}"
_has_opt "${_opt}" "bad-ssl" && _has_opt "${_opt}" "weak-ssl" && _usage
_name=$(_get_name "${_ver}" "${_opt}")

_pkgs="make perl autoconf"
case "${_ver}" in
	7.70) ;;
	7.80|7.90|8.00) _pkgs="${_pkgs} flex bison" ;;
	head) _pkgs="${_pkgs} flex bison git" ;;
	*) _err "invalid nmap version: ${_ver}" ;;
esac
_has_opt "${_opt}" "bad-ssl" && _pkgs="${_pkgs} git"

_check() {
	docker inspect --type=image "moo/static-nmap:${_name}.${_target}" > /dev/null 2>&1
	return $?
}

case $_action in
	check) _check; exit $? ;;
	build)
		_prepare "build-nmap.sh" zlib openssl nmap
		_build_docker "musl" \
			"moo/static-nmap:${_name}.${_target}" \
			"${_arch}" "${_pkgs}" \
			"build-nmap.sh" "${_ver}" "${_opt}"
		;;
	pack)
		! _check && _err "not built jet."
		cd -- "${_cdir}" || _err "cannot cd to ${_cdir}"
		command -v sort >/dev/null 2>&1 || _err "sort not available."
		_tmp="${_cdir}/out/tmp"; rm -rf -- "${_tmp}"; mkdir -p -- "${_tmp}" || _err "mkdir ${_tmp}"
		echo "- dump ${_name}.${_target}"
		docker run --rm \
			-i "moo/static-nmap:${_name}.${_target}" \
			tar -czf - -C /cross . > "${_tmp}/dump.tar.gz" || _err "docker+tar"
		tar -xzf "${_tmp}/dump.tar.gz" -C "${_tmp}" || _err "tar"
		_pack() {  # 1 - prefix
			_fname="$1-${_name}.${_target}"
			_out="${_cdir}/out/${_fname}"; rm -rf -- "${_out}"; mkdir -p -- "${_out}" || _err "mkdir ${_out}"
			echo "- pack ${_fname}"
			strip --strip-all "${_tmp}/bin/$1" > /dev/null 2>&1 
			mv "${_tmp}/bin/$1" "${_out}" || _err "mv"
			if [ -f "${_tmp}/bin/$1.sh" ]; then
				chmod a+x "${_tmp}/bin/$1.sh"
				mv "${_tmp}/bin/$1.sh" "${_out}" || _err "mv"
			fi
			mv "${_tmp}/share/man/man1/$1.1" "${_out}" || _err "mv"
			if [ -d "${_tmp}/share/$1" ]; then
				mv "${_tmp}/share/$1" "${_out}/$1-data" || _err "mv"
			fi
			rm -f -- "${_out}.tar.gz"
			tar -czf "${_out}.tar.gz" -C "${_cdir}/out" "${_fname}" || _err "tar"
			rm -rf -- "${_out}"
		}
		echo "- copy vulners scripts"
		_vulners="${_cdir}/files/nmap-vulners"
		cp "${_vulners}/vulners.nse" "${_tmp}/share/nmap/scripts/" || _err "cp"
		cp "${_vulners}/http-vulners-regex.nse" "${_tmp}/share/nmap/scripts/" || _err "cp"
		cp "${_vulners}/http-vulners-regex.json" "${_tmp}/share/nmap/nselib/data/" || _err "cp"
		cp "${_vulners}/http-vulners-paths.txt" "${_tmp}//share/nmap/nselib/data/" || _err "cp"
		echo 'Entry { filename = "vulners.nse", categories = { "default", "external", "safe", "vuln", } }' >> "${_tmp}/share/nmap/scripts/script.db"
		echo 'Entry { filename = "http-vulners-regex.nse", categories = { "default", "safe", } }' >> "${_tmp}/share/nmap/scripts/script.db"
		sort "${_tmp}/share/nmap/scripts/script.db" -o "${_tmp}/share/nmap/scripts/script.db" || _err "sort"
		echo "- copy wrapper scripts"
		cp "${_cdir}/files/nmap.sh" "${_tmp}/bin/"
		cp "${_cdir}/files/ncat.sh" "${_tmp}/bin/"
		_pack nmap
		_pack ncat
		_pack nping
		rm -rf -- "${_tmp}"
		;;
	*) _usage ;;
esac

exit 0
