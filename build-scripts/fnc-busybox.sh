#!/bin/sh

_build_musl_busybox() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="busybox-${BUSYBOX_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "busybox" "${BUSYBOX_VERSION}" "https://busybox.net/downloads/" "tar.bz2"
	_msg "configuring ${_name}"
	make defconfig HOSTCC=/usr/bin/cc
	sed -i'' 's#CONFIG_FEATURE_SUID=y#CONFIG_FEATURE_SUID=n#' .config
	sed -i'' 's#CONFIG_ASH_MAIL=y#CONFIG_ASH_MAIL=n#' .config
	sed -i'' 's#CONFIG_FEATURE_EDITING_SAVEHISTORY=y#CONFIG_FEATURE_EDITING_SAVEHISTORY=n#' .config
	sed -i'' 's#CONFIG_HUSH_SAVEHISTORY=y#CONFIG_HUSH_SAVEHISTORY=n#' .config
	sed -i'' 's#CONFIG_FEATURE_SH_HISTFILESIZE=y#CONFIG_FEATURE_SH_HISTFILESIZE=n#' .config
	_msg "building ${_name}"
	LDFLAGS="--static" make CC="/bin/cc -static" || _err "make"
	_msg "installing ${_name}"
	mkdir -p "${_out}"
	mv busybox "${_out}/busybox"
        file "${_out}/busybox"
        "${_out}/busybox"
}
