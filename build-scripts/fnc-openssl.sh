#!/bin/sh

# shellcheck disable=SC2120
_build_musl_openssl() {
	if [ "${OPENSSL_VERSION}" = "1.0.2-bad" ]; then
		_build_musl_openssl102bad "$@"
	elif echo "${OPENSSL_VERSION}" | grep -q -e '^1.1.0[a-l]\?$' -e '^1.1.1[a-z]\?$'; then
		_build_musl_openssl11xy "$@"
	else
		_err "unknown openssl version: ${OPENSSL_VERSION}"
	fi
}

_get_openssl_arch() {
	case "${MUSL_ARCH}" in
		*i486*|*i586*|*i686*)
			# fix target (e.g., openssl-1.1.0 doesn't support linux-x86)
			if ./Configure LIST | grep -q '^linux-x86$'; then
				_openssl_arch="linux-x86"
			elif ./Configure LIST | grep -q '^linux-elf$'; then
				_openssl_arch="linux-elf"
			elif ./Configure LIST | grep -q '^linux-generic32$'; then
				_openssl_arch="linux-generic32"
			else
				_err "cannot choose x86 arch"
			fi
			;;
		*x86_64*|*amd64*)
			if ./Configure LIST | grep -q '^linux-x86_64$'; then
				_openssl_arch="linux-x86_64"
			else
				_err "cannot choose x64 arch"
			fi
			;;
		*) _err "unknown architecture: ${MUSL_ARCH}" ;;
	esac
	echo "${_openssl_arch}" && return 0
}

_build_musl_openssl102bad() {  # 1 - output, 2 - dependencies
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	command -v git >/dev/null 2>&1 || _err "git not available."
	_cd "${BUILD_DIR}"
	git clone --depth=1 "https://github.com/drwetter/openssl-1.0.2.bad" "openssl-1.0.2.bad" || _err "git clone"
	_cd "openssl-1.0.2.bad"
	patch -p1 < fedora-dirk-ipv6.patch >/dev/null 2>&1
	_openssl_arch=$(_get_openssl_arch) || _err "cannot determine openssl arch"
	_openssl_options="no-shared -static enable-ssl-trace -DOPENSSL_USE_IPV6"
	if _has_opt "${OPENSSL_OPT}" "zlib"; then
		_openssl_options="${_openssl_options} enable-zlib"
	fi
	_openssl_options="${_openssl_options} \
		enable-camellia \
		enable-cms \
		enable-ec \
		enable-ec2m \
		enable-ecdh \
		enable-ecdsa \
		enable-gost \
		enable-idea \
		enable-md2 \
		enable-mdc2 \
		enable-rc2 \
		enable-rc5 \
		enable-rfc3779 \
		enable-seed \
		enable-ssl2 \
		enable-ssl3 \
		experimental-jpake"
	case "${MUSL_ARCH}" in
		*i486*|*i586*|*i686*) _openssl_options="${_openssl_options} no-ec_nistp_64_gcc_128" ;;
		*x86_64*|*amd64*) _openssl_options="${_openssl_options} enable-ec_nistp_64_gcc_128" ;;
		*) _err "unknown architecture: ${MUSL_ARCH}" ;;
	esac
        # shellcheck disable=SC2086
        ./Configure "${_openssl_arch}" \
                --prefix="${_out}" \
                -I"${_dep}/include" \
                -L"${_dep}/lib" \
                ${_openssl_options} || _err "Configure"
        perl configdata.pm --dump
        make depend || _err "make depend"
        make || _err "make"
        make install || _err "make install"
	"${_out}/bin/openssl" ciphers -V 'ALL:COMPLEMENTOFALL'
	"${_out}/bin/openssl" ciphers -V 'ALL:COMPLEMENTOFALL' | wc -l
}

_build_musl_openssl11xy() {  # 1 - output, 2 - dependencies
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	command -v tar >/dev/null 2>&1 || _err "tar not available."
	_fetch_and_extract "openssl" "${OPENSSL_VERSION}" "https://www.openssl.org/source/"
	# fix Perl module (openssl-1.1.0 ... openssl-1.1.0?)
	if grep -q "'File::Glob' => qw/glob/;" Configure; then
		find ./ -type f -exec sed -i'' "s#'File::Glob' => qw/glob/;#'File::Glob' => qw/bsd_glob/;#g" {} \;
	fi
	_openssl_arch=$(_get_openssl_arch) || _err "cannot determine openssl arch"
	_openssl_options="no-shared -static enable-ssl-trace"
	if _has_opt "${OPENSSL_OPT}" "zlib"; then
		_openssl_options="${_openssl_options} enable-zlib"
	fi
        if _has_opt "${OPENSSL_OPT}" "weak-ssl"; then
		_openssl_options="${_openssl_options} \
			enable-md2 \
			enable-rc5 \
			enable-weak-ssl-ciphers \
			enable-ssl3 enable-ssl3-method \
			-DOPENSSL_TLS_SECURITY_LEVEL=0"
        fi
        # shellcheck disable=SC2086
        ./Configure "${_openssl_arch}" \
                --prefix="${_out}" \
                -I"${_dep}/include" \
                -L"${_dep}/lib" \
                ${_openssl_options} || _err "Configure"
        perl configdata.pm --dump
        make || _err "make"
        make install || _err "make install"
	"${_out}/bin/openssl" ciphers -V 'ALL:COMPLEMENTOFALL'
	"${_out}/bin/openssl" ciphers -V 'ALL:COMPLEMENTOFALL' | wc -l
}
