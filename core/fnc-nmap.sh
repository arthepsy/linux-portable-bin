#!/bin/sh

# shellcheck disable=SC2120
_build_musl_nmap() {
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	_name="nmap-${NMAP_VERSION}"
	_msg "downloading ${_name}"
	if [ "${NMAP_VERSION}" = "head" ]; then
		command -v git >/dev/null 2>&1 || _err "git not available."
		_cd "${BUILD_DIR}"
		git clone --depth=1 "https://github.com/nmap/nmap.git" "nmap-head" || _err "git"
		_cd "nmap-head"
	else
		_fetch_and_extract "nmap" "${NMAP_VERSION}" "https://nmap.org/dist/" "tar.bz2"
	fi
	_msg "patching ${_name}"
	find ./ -name 'configure*' -exec sed -i'' 's/OPENSSL_LIBS="-lssl -lcrypto"/OPENSSL_LIBS="-lssl -lcrypto -lz"/g' {} \;
	_msg "configuring ${_name}"
	CC="gcc -static -fPIC" \
	CXX="g++ -static -static-libstdc++ -fPIC" \
	./configure \
		--prefix="${_out}" \
		--host "$(gcc -dumpmachine | cut -d '-' -f 1)-unknown-linux-gnu" \
		--without-ndiff \
		--without-zenmap \
		--without-nmap-update \
		--with-pcap=linux \
		--with-libz="${_dep}" \
		--with-openssl="${_dep}" || _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
	"${_out}/bin/nmap" -V
}
