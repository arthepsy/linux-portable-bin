#!/bin/sh
_cdir=$(cd -- "$(dirname "$0")" && pwd)
_err() { echo "err: $1" >&2 && exit 1; }
_cd() { cd -- "$1" || _err "directory $1 does not exist"; }

[ -z "${XCI_DIR}" ] && _err "XCI_DIR variable is empty."
[ -z "${XCI_ARCH}" ] && _err "XCI_ARCH variable is empty."
XCI_VER=${XCI_VER:-}
XCI_OPT=${XCI_OPT:-}

_cd "${_cdir}/${XCI_DIR}"
while IFS= read -r _xarch <&3; do
	set -- build "${_xarch}" "${XCI_VER}" "${XCI_OPT}"
	if ! ./run.sh "$@"; then _err "fail"; fi
	set -- pack "${_xarch}" "${XCI_VER}" "${XCI_OPT}"
	if ! ./run.sh "$@"; then _err "fail"; fi
done 3<<-EOF
	$(printf "%s\n" "${XCI_ARCH}" | tr ' ' '\n')
EOF
_cd "${_cdir}"
exit 0
