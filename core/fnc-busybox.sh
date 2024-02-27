#!/bin/sh

_build_musl_busybox() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="busybox-${BUSYBOX_VERSION}"
	_patch1=0
	case "${BUSYBOX_VERSION}-${BUILD_ARCH}" in
		# fix x86 bug in 1.36.x (disable hardware accel for sha1/sha256)
		1.36.0-i486*|1.36.0-i586*|1.36.0-i686*) _patch1=1 ;;
		1.36.1-i486*|1.36.1-i586*|1.36.1-i686*) _patch1=1 ;;
		*) ;;
	esac
	_msg "downloading ${_name}"
	_fetch_and_extract "busybox" "${BUSYBOX_VERSION}" "http://sources.openwrt.org/" "tar.bz2"
	# _fetch_and_extract "busybox" "${BUSYBOX_VERSION}" "https://busybox.net/downloads/" "tar.bz2"
	if [ ${_patch1} -eq 1 ]; then
		_msg "patching ${_name} (patch1a)"
		sed -i'' -e 's#lib-y += hash_md5_sha_x86-32_shaNI.o##' libbb/Kbuild.src
		sed -i'' -e 's#lib-y += hash_md5_sha256_x86-32_shaNI.o##' libbb/Kbuild.src
	fi

	_msg "patching ${_name}"
	for _f in ../patch-alpine-*; do
		patch -p1 < "${_f}" || _err "failed to patch ${_name} with ${_f}"
	done
	for _f in ../patch-moo-*; do
		patch -p1 < "${_f}" || _err "failed to patch ${_name} with ${_f}"
	done
	for _f in ../script-*.sh; do
		_fn=$(basename "${_f}")
		_fn2=$(printf "%s" "${_fn}" | sed -e 's#^script-##' -e 's#.sh$##')
		_msg "add script ${_fn2}"
		cp "../script-${_fn2}.sh" "./applets_sh/${_fn2}" || _err "failed to copy ../script-${_fn2}.sh"
		chmod a+x "./applets_sh/${_fn2}"
		cp "../script-${_fn2}.c" "./miscutils/${_fn2}.c" || _err "failed to copy ../script-${_fn2}.c"
	done

	_msg "configuring ${_name}"
	make defconfig HOSTCC=/usr/bin/cc
	# static
	sed -i'' -e 's#^[\# ]*\(CONFIG_PIE\)[= ].*#\# \1 is not set#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_STATIC\)[= ].*#\1=y#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_SSL_CLIENT\)[= ].*#\1=y#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_EXTRA_COMPAT\)[= ].*#\1=n#' .config
	# general config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_SUID\)[= ].*#\1=n#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_UNAME_OSNAME\)[= ].*#\1="Linux"#' .config
	# linux modules
	sed -i'' -e 's#^[\# ]*\(CONFIG_MODPROBE_SMALL\)[= ].*#\# \1 is not set#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_LSMOD_PRETTY_2_6_OUTPUT\)[= ].*#\1=y#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_MODPROBE_BLACKLIST\)[= ].*#\1=y#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_MODUTILS_BIN\)[= ].*#\1=y#' .config
	# ash config
	sed -i'' -e 's#^[\# ]*\(CONFIG_ASH_MAIL\)[ =].*#\1=n#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_ASH_VERSION_VAR\)[= ].*#\1=y#' .config
	# disable history
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_EDITING_SAVEHISTORY\)[ =].*#\1=n#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_HUSH_SAVEHISTORY\)[ =].*#\1=n#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_SH_HISTFILESIZE\)[ =].*#\1=n#' .config
	# enable stand-alone shell
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_SH_STANDALONE\)[ =].*#\1=y#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_PREFER_APPLETS\)[ =].*#\1=y#' .config
	sed -i'' -e 's#^[\# ]*\(CONFIG_FEATURE_SH_NOFORK\)[= ].*#\1=y#' .config
	# disable broken hw-accel on x86
	if [ ${_patch1} -eq 1 ]; then
		_msg "patching ${_name} (patch1b)"
		sed -i'' -e 's#^[\# ]*\(CONFIG_SHA1_HWACCEL\)[ =].*#\1=n#' .config
		sed -i'' -e 's#^[\# ]*\(CONFIG_SHA256_HWACCEL\)[ =].*#\1=n#' .config
	fi

	_msg "building ${_name}"
	LDFLAGS="--static" make CC="/bin/cc -static" || _err "make"
	_msg "installing ${_name}"
	mkdir -p "${_out}"
	cp busybox "${_out}/busybox"
	grep 'CONFIG_' .config > "${_out}/busybox.config"

        file "${_out}/busybox"
        ls -al "${_out}/busybox"
        "${_out}/busybox"
}
