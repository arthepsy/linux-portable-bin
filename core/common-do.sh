#!/bin/sh

_err() { echo "err: $1" >&2 && exit 1; }

_is_func() { LC_ALL=C type "$1" 2>/dev/null | grep -q 'function'; }

_usage() {
	_VERSION="${_VERSION:-unknown}"
	_is_func '_pkg_usage' && _pkg_usage
	printf "usage: %s check|build|pack <target> <version> [<options>]\n" "$0"
	printf "\ntarget:\n"
	printf "\tx86\tx86 32-bit\n"
	printf "\tx64\tx86 64-bit\n"
	printf "\nversion:\n"
	_dots=$(printf '%s' "${_VERSION}" | tr -dc '.')
	if [ "${_dots}" = ".." ]; then
		printf '\tA.B.C\t'
	elif [ "${_dots}" = "." ]; then
		printf '\tA.B\t'
	else
		printf '\tXXX\t'
	fi
	printf 'use specific version, e.g., %s\n' "${_VERSION}"
	if [ -n "${_OPTS:-}" ]; then
		printf '\noptions:\n'
		printf '%s' "${_OPTS}" | tr '|' '\n' | sed -e 's#^#\t#'
	fi
	printf "\nexample:\n      %s build x64 %s\n\n" "$0" "${_VERSION}"
        exit 1
}

_get_musl_arch() {
	case "$1" in
		x86) printf "i486-linux-musl" && return 0 ;;
		x64) printf "x86_64-linux-musl" && return 0 ;;
	        *) return 1 ;;
	esac
}

_get_dockcross_arch() {
	case "$1" in
		x86) printf "x86" && return 0 ;;
		x64) printf "x64" && return 0 ;;
	        *) return 1 ;;
	esac
}

_get_arch() {  # 1 - backend, 2 - target
	case "$1" in
		musl) _get_musl_arch "$2" ;;
		dockcross*) _get_dockcross_arch "$2" ;;
		*) _err "unknown backend: $1" ;;
	esac
}

_parse_args() {
	[ $# -lt 2 ] && _usage
	_ACTION="$1"
	_DEBUG=""
	if [ "${_ACTION}" = "debug" ]; then
		_ACTION="build"
		_DEBUG="debug"
	fi
	_TARGET="$2"
	_BACKEND="${_BACKEND:-musl}"
	_ARCH=$(_get_arch "${_BACKEND}" "${_TARGET}") || _err "unknown target: ${_TARGET}"
	_VERSION="${3:-$_VERSION}"
}

_opt_req() {
	for _cmd in cut grep tr sort sed; do
		command -v "${_cmd}" >/dev/null 2>&1 || _err "${_cmd} not available."
	done
}

_has_opt() { printf '%s' "$1" | tr '|' '\n' | grep -q "^${2}$"; return $?; }

_get_opt() {  # 1 - valid options, #2+ - options
	_opts=""
	_vopts=$1
	shift
	for _opt in "$@"; do
		[ -z "${_opt}" ] && continue
		printf '%s' "${_vopts}" | tr '|' '\n' | grep -q "^${_opt}$"
		if [ $? -eq 1 ]; then
			printf 'unknown option: %s\n'  "${_opt}" && return 1
		fi
		_opts="${_opts}|${_opt}"
	done
	printf '%s' "${_opts}" | cut -c2-
	return 0
}

_parse_opts() {
	shift 2; [ "$#" -gt 0 ] && shift
	_opt_req
	_OPT=$(_get_opt "${_OPTS:-}" "$@") || _err "${_OPT}"
}

_get_ver_full() {  #1 - version, #2 - options
	_ver="$1"
	if [ -n "$2" ]; then
		_ver="${_ver}.$(printf '%s' "$2" | tr '|' '\n' | sort | tr '\n' '.' | sed -e 's/.$//')"
	fi
	printf '%s' "${_ver}"
}

_do_check() {
	docker inspect --type=image "${_DOCKER_IMAGE_NAME}" > /dev/null 2>&1
	return $?
}

_prepare() {  # 1 - name, #2+ - includes
	_bs="${_SDIR}/../../core"
	_tn="${_SDIR}/fnc-build.sh"
	_sn="${_SDIR}/$1"
	shift
	{
		printf '#!/bin/sh\n'
		for _n in common-build "$@"; do
			tail -n +2 "${_bs}/${_n}.sh" 2>/dev/null || _err "../../core/${_n}.sh does not exist"
		done
		tail -n +2 "${_tn}" 2>/dev/null || _err "init-build.sh does not exist"
		printf '\n_init\n_build\n_done\n\n'
	} > "${_sn}"
}

_do_build() {
	_docker_script="build-${_NAME}.sh"
	_prepare "${_docker_script}" "${_NAME}"
	case "${_BACKEND}" in
		musl|dockcross|dockcross-*) _docker_type="${_BACKEND}" ;;
		*) _err "unknown backend: ${_BACKEND}" ;;
	esac
	_build_docker "${_docker_type}" "${_DOCKER_IMAGE_NAME}" "${_ARCH}" "${_PKGS}" "${_docker_script}" "${_VERSION}" "${_OPT}" "${_DEBUG}"
}

_build_docker() {  #1 - docker type, #2 - docker name, #3 - arch, #4 - pkgs, #5 - script, #6 - version, #7 - options, #8 - debug
	[ $# -lt 7 ] && _err "usage: <docker_type> <docker_name> <build_arch> <build_pkgs> <build_script> <build_ver> <build_opt> [<debug>]"
	cd -- "${_SDIR}" || _err "cannot cd to ${_SDIR}"
	_bs="${_SDIR}/../../core"
	for _fn in "Dockerfile.$1" "dot.dockerignore"; do
		[ ! -f "${_bs}/${_fn}" ] && _err "does not exist: ${_fn}"
	done
	_docker_args=""
	case "$8" in
		[dD][eE][bB][uU][gG]) _docker_args="${_docker_args} --target builder" ;;
		*) ;;
	esac
	if [ -n "${NOCACHE:-}" ]; then
		_docker_args="${_docker_args} --no-cache"
	fi
	cp "${_bs}/Dockerfile.$1" "${_SDIR}/Dockerfile.$1" || _err "cp Dockerfile.$1"
	cp "${_bs}/dot.dockerignore" "${_SDIR}/.dockerignore" || _err "cp .dockerignore"
	if [ ! -d "${_SDIR}/files" ]; then
		mkdir -p "${_SDIR}/files"
	fi
	# shellcheck disable=SC2086
	env DOCKER_BUILDKIT=1 \
	docker build \
		--progress=plain \
		--build-arg BUILD_TYPE="$1" \
		--build-arg BUILD_ARCH="$3" \
		--build-arg BUILD_PKGS="$4" \
		--build-arg BUILD_SCRIPT="$5" \
		--build-arg BUILD_VERSION="$6" \
		--build-arg BUILD_OPT="$7" \
		${_docker_args} \
		-t "$2" \
		-f "Dockerfile.$1" . || _err "docker"
	_ec=$?
	rm -f "${_SDIR}/.dockerignore" "${_SDIR}/Dockerfile.$1" "${_SDIR}/$5"
	return "${_ec}"
}

_docker_strip() {  #1 - dir, 2+ - bin
	_dir="$1"
	cd -- "${_dir}" || _err "cannot cd to ${_dir}"
	_h=$(pwd | md5sum)
	_dname="moo_strip_${_h}"
	docker run -d --rm -it --name "${_dname}" alpine:3 sh > /dev/null 2>&1 || _err "docker run"
	docker exec "${_dname}" sh -c 'mkdir -p /work; cd /opt; wget https://github.com/upx/upx/releases/download/v4.2.2/upx-4.2.2-amd64_linux.tar.xz; tar xf upx-4.2.2-amd64_linux.tar.xz; mv upx-*/upx . ; rm -rf upx-*' > /dev/null 2>&1
	docker exec "${_dname}" sh -c 'apk add binutils' > /dev/null 2>&1
	shift;
	while [ $# -ne 0 ]; do
		_bin="$1"
		docker cp "${_bin}" "${_dname}:/work/"
		docker exec "${_dname}" sh -c "cd /work; ls -al \"${_bin}\"; strip -s \"${_bin}\"; /opt/upx --best --ultra-brute \"${_bin}\""
		docker cp "${_dname}:/work/${_bin}" "${_bin}"
		shift
	done
	docker kill "${_dname}" > /dev/null 2>&1
}

_do_pack_check() {
	! _do_check && _err "${_NAME_FULL} not built yet."
}

_do_pack_dump() {
	cd -- "${_SDIR}" || _err "cannot cd to ${_SDIR}"
	_tmp="${_SDIR}/out/tmp"; rm -rf -- "${_tmp}"; mkdir -p -- "${_tmp}" || _err "mkdir ${_tmp}"
	printf -- '- dump %s\n' "${_NAME_FULL}"
	docker run --rm -i "${_DOCKER_IMAGE_NAME}" tar -czf - -C /cross . > "${_tmp}/dump.tar.gz" || _err "docker+tar"
	tar -xzf "${_tmp}/dump.tar.gz" -C "${_tmp}" || _err "tar"
	rm -f "${_tmp}/dump.tar.gz"
}

_do_pack_strip() {
	printf -- '- strip %s\n' "${_NAME_FULL}"
	_tmp="${_SDIR}/out/tmp"
	cd -- "${_tmp}" || return
	for _f in *; do
		file -b "${_f}" 2>/dev/null | grep -q '^ELF '; _ec=$?
		[ $_ec -ne 0 ] && continue
		_docker_strip "${_tmp}" "${_f}"
	done
	cd -- "${_SDIR}" || _err "cannot cd to ${_SDIR}"
}

_do_pack_archive() {
	printf -- '- pack %s\n' "${_NAME_FULL}"
	_tmp="${_SDIR}/out/tmp"
	_out="${_SDIR}/out/${_NAME_FULL}"; rm -rf -- "${_out}"; mkdir -p -- "${_out}" || _err "mkdir ${_out}"
	cp -R "${_tmp}"/* "${_out}/" || _err "cp -R ${_tmp}/* ${_out}/"
	rm -f -- "${_out}.tar.gz"
	tar -czf "${_out}.tar.gz" -C "${_SDIR}/out" "${_NAME_FULL}" || _err "tar"
}

_do_pack_cleanup() {
	_tmp="${_SDIR}/out/tmp"
	_out="${_SDIR}/out/${_NAME_FULL}"
	rm -rf -- "${_tmp}"
	rm -rf -- "${_out}"
}

_do_pack() {
	_do_pack_check
	_do_pack_dump
	_do_pack_strip
	_do_pack_archive
	_do_pack_cleanup
}

_pkg_main() {
	[ -z "${_NAME}" ] && _err: "_NAME must be defined."
	_SDIR=$(cd -- "$(dirname "$0")" && pwd)
	_parse_opts "$@"
	_is_func '_pkg_post_opts' && _pkg_post_opts
	_parse_args "$@"
	_PKGS="${_PKGS:-}"
	_VERSION_FULL="$(_get_ver_full "${_VERSION}" "${_OPT}")"
	_NAME_FULL="${_NAME}-${_VERSION_FULL}.${_TARGET}"
	_DOCKER_IMAGE_NAME="moo/static-${_NAME}:${_VERSION_FULL}.${_TARGET}"
	_fn_pkg="_pkg_${_ACTION}"
	if _is_func "${_fn_pkg}"; then
			${_fn_pkg}
	else
		_fn_do="_do_${_ACTION}"
		if _is_func "${_fn_do}"; then
			${_fn_do}
		else
			_usage
		fi
	fi
}

