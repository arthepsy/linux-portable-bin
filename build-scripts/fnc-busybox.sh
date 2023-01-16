#!/bin/sh

_build_musl_busybox() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="busybox-${BUSYBOX_VERSION}"
	_patch1=0
	case "${BUSYBOX_VERSION}-${BUILD_ARCH}" in
		# fix x86 bug in 1.36.0 (disable hardware accel for sha1/sha256)
		1.36.0-i486*|1.36.0-i586*|1.36.0-i686*) _patch1=1 ;;
		*) ;;
	esac
	_msg "downloading ${_name}"
	_fetch_and_extract "busybox" "${BUSYBOX_VERSION}" "https://sources.openwrt.org/" "tar.bz2"
	# _fetch_and_extract "busybox" "${BUSYBOX_VERSION}" "https://busybox.net/downloads/" "tar.bz2"
	if [ ${_patch1} -eq 1 ]; then
		_msg "patching ${_name} (patch1a)"
		sed -i'' 's#lib-y += hash_md5_sha_x86-32_shaNI.o##' libbb/Kbuild.src
		sed -i'' 's#lib-y += hash_md5_sha256_x86-32_shaNI.o##' libbb/Kbuild.src
	fi
	_msg "configuring ${_name}"
	make defconfig HOSTCC=/usr/bin/cc
	sed -i'' 's#CONFIG_FEATURE_SUID=y#CONFIG_FEATURE_SUID=n#' .config
	sed -i'' 's#CONFIG_ASH_MAIL=y#CONFIG_ASH_MAIL=n#' .config
	sed -i'' 's#CONFIG_FEATURE_EDITING_SAVEHISTORY=y#CONFIG_FEATURE_EDITING_SAVEHISTORY=n#' .config
	sed -i'' 's#CONFIG_HUSH_SAVEHISTORY=y#CONFIG_HUSH_SAVEHISTORY=n#' .config
	sed -i'' 's#CONFIG_FEATURE_SH_HISTFILESIZE=y#CONFIG_FEATURE_SH_HISTFILESIZE=n#' .config
	if [ ${_patch1} -eq 1 ]; then
		_msg "patching ${_name} (patch1b)"
		sed -i'' 's#CONFIG_SHA1_HWACCEL=y#CONFIG_SHA1_HWACCEL=n#' .config
		sed -i'' 's#CONFIG_SHA256_HWACCEL=y#CONFIG_SHA256_HWACCEL=n#' .config
	fi
	_msg "building ${_name}"
	LDFLAGS="--static" make CC="/bin/cc -static" || _err "make"
	_msg "installing ${_name}"
	mkdir -p "${_out}"
	mv busybox "${_out}/busybox"
        file "${_out}/busybox"
        "${_out}/busybox"
}
