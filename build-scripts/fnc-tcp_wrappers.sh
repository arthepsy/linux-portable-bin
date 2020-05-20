#!/bin/sh

TCP_WRAPPERS_VERSION=7.6  # last release 1997-04-08 

_build_musl_tcp_wrappers() {
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_fetch_and_extract "tcp_wrappers_" "${TCP_WRAPPERS_VERSION}" "http://ftp.porcupine.org/pub/security/"
	# patch to use strerror()
	sed -i'' -e '32istrcpy(bp, strerror(errno)); /*' -e '37i*/' percent_m.c || _err "sed"
	make REAL_DAEMON_DIR=/usr/sbin STYLE=-DPROCESS_OPTIONS LIBS= RANLIB=ranlib ARFLAGS=rv AUX_OBJ=setenv.o NETGROUP= TLI= EXTRA_CFLAGS="" all || _err "make"
	mkdir -p -- "${_out}/lib" "${_out}/include" || _err "mkdir"
	cp "libwrap.a" "${_out}/lib/" || _err "cp"
	cp "tcpd.h" "${_out}/include/" || _err "cp"
}
