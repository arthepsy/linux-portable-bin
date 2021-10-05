#!/bin/sh

TCP_WRAPPERS_VERSION=7.6  # last release 1997-04-08 

_build_musl_tcp_wrappers() {
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="tcp_wrappers-${TCP_WRAPPERS_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "tcp_wrappers_" "${TCP_WRAPPERS_VERSION}" "http://ftp.porcupine.org/pub/security/"
	_msg "patching ${_name}"
	# patch to use strerror()
	sed -i'' -e '32istrcpy(bp, strerror(errno)); /*' -e '37i*/' percent_m.c || _err "sed"
	_msg "building ${_name}"
	make REAL_DAEMON_DIR=/usr/sbin STYLE=-DPROCESS_OPTIONS LIBS= RANLIB=ranlib ARFLAGS=rv AUX_OBJ=setenv.o NETGROUP= TLI= EXTRA_CFLAGS="" all || _err "make"
	_msg "installing ${_name}"
	mkdir -p -- "${_out}/lib" "${_out}/include" || _err "mkdir"
	cp "libwrap.a" "${_out}/lib/" || _err "cp"
	cp "tcpd.h" "${_out}/include/" || _err "cp"
}
