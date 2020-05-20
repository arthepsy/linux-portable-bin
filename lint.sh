#!/bin/sh
_cdir=$(cd -- "$(dirname "$0")" && pwd)

_get_shellcheck() {
        command -v shellcheck >/dev/null 2>&1 && echo "shellcheck" && return 0
	command -v "$HOME/.cabal/bin/shellcheck" >/dev/null 2>&1 && echo "$HOME/.cabal/bin/shellcheck" && return 0
        return 1
}

if [ "$1" = "shell" ] || [ -z "$1" ]; then
	_shellcheck=$(_get_shellcheck)
	find "${_cdir}" -mindepth 1 -maxdepth 2 -type f -name "*.sh" | while read -r _shellscript; do
		echo "- lint ${_shellscript}"
		if [ -n "${_shellcheck}" ]; then
			${_shellcheck} "${_shellscript}"
		fi
	done
fi

if [ "$1" = "docker" ] || [ -z "$1" ]; then
	find "${_cdir}" -mindepth 2 -maxdepth 2 -type f -name "Dockerfile.*" | while read -r _dockerfile; do
		echo "- lint ${_dockerfile}"
		docker run --rm -i hadolint/hadolint < "${_dockerfile}"
	done
fi
