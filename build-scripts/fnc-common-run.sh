#!/bin/sh

_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }

_prepare() {  # 1 - script name, #2+ - includes
	_bs="${_cdir}/../build-scripts"
	_tn="${_cdir}/tpl-$1"
	_sn="${_cdir}/$1"
	shift
	{
		printf "#!/bin/sh\n"
		for _n in common-build "$@"; do
			tail -n +2 "${_bs}/fnc-${_n}.sh" || _err "fnc-${_n}.sh does not exist"
		done
		tail -n +2 "${_tn}" || _err "${_tn} does not exist"
	} > "${_sn}"
}

_get_musl_arch() {
	case "$1" in
		x86) echo "i486-linux-musl" && return 0 ;;
		x64) echo "x86_64-linux-musl" && return 0 ;;
	        *) return 1 ;;
	esac
}

_get_dockcross_arch() {
	case "$1" in
		x86) echo "linux-x86" && return 0 ;;
		x64) echo "linux-x64" && return 0 ;;
	        *) return 1 ;;
	esac
}

_opt_req() {
	for _cmd in cut grep tr sort sed; do
		command -v "${_cmd}" >/dev/null 2>&1 || _err "${_cmd} not available."
	done
}

_has_opt() { echo "$1" | tr '|' '\n' | grep -q "^${2}$"; return $?; }

_get_opt() {  # 1 - valid options, #2+ - options
	_opts=""
	_vopts=$1
	shift
	for _opt in "$@"; do
		[ -z "${_opt}" ] && continue
		echo "${_vopts}" | tr '|' '\n' | grep -q "^${_opt}$"
		if [ $? -eq 1 ]; then
			echo "unknown option: $_opt" && return 1
		fi
		_opts="${_opts}|${_opt}"
	done
	echo "${_opts}" | cut -c2-
	return 0
}

_get_name() {  #1 - version, #2 - options
	_name="$1"
	if [ -n "$2" ]; then
		_name="${_name}.$(echo "$2" | tr '|' '\n' | sort | tr '\n' '.' | sed -e 's/.$//')"
	fi
	echo "${_name}"
}

_build_docker() {  #1 - docker type, #2 - docker name, #3 - arch, #4 - pkgs, #5 - script, #6 - version, #7 - options
	[ $# -lt 7 ] && _err "usage: <docker_type> <docker_name> <build_arch> <build_pkgs> <build_script> <build_ver> <build_opt>"
	cd -- "${_cdir}" || _err "cannot cd to ${_cdir}"
	_bs="${_cdir}/../build-scripts"
	for _fn in "Dockerfile.$1" "dot.dockerignore"; do
		[ ! -f "${_bs}/${_fn}" ] && _err "does not exist: ${_fn}"
	done
	cp "${_bs}/Dockerfile.$1" "${_cdir}/Dockerfile.$1" || _err "cp Dockerfile.$1"
	cp "${_bs}/dot.dockerignore" "${_cdir}/.dockerignore" || _err "cp .dockerignore"
	env DOCKER_BUILDKIT=1 \
	docker build \
		--no-cache \
		--progress=plain \
		--build-arg BUILD_TYPE="$1" \
		--build-arg BUILD_ARCH="$3" \
		--build-arg BUILD_PKGS="$4" \
		--build-arg BUILD_SCRIPT="$5" \
		--build-arg BUILD_VERSION="$6" \
		--build-arg BUILD_OPT="$7" \
		-t "$2" \
		-f "Dockerfile.$1" . || _err "docker"
	_ec=$?
	rm -f "${_cdir}/Dockerfile.$1" "${_cdir}/$5"
	return "${_ec}"
}

