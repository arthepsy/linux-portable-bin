#!/bin/sh

# shellcheck disable=SC2120
_build_musl_graftcp() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="graftcp-${GRAFTCP_VERSION}"
	_msg "downloading ${_name}"
	if [ "${GRAFTCP_VERSION}" == "head" ]; then
		git clone "https://github.com/hmgle/graftcp" "${_name}" || _err "git clone failed"
		_cd "${_name}"
	else
		mkdir -p "${_name}"
		_cd "${_name}"
		git init || _err "git init failed"
		git remote add origin "https://github.com/hmgle/graftcp" || _err "git remote failed"
		git fetch --depth 1 origin "v${GRAFTCP_VERSION}" || _err "git fetch failed"
		git checkout FETCH_HEAD || _err "git checkout failed"
	fi
	_msg "building ${_name}"
	CC=/bin/cc CROSS_COMPILE=/bin/ make || _err "make"
	_msg "building static ${_name}"
	case "${GRAFTCP_VERSION}" in
		0.4.0) /bin/cc -static -fPIC main.o graftcp.o util.o string-set.o -o graftcp || _err "cc -static failed" ;;
		*) /bin/cc -static -fPIC main.o graftcp.o util.o string-set.o conf.o -o graftcp || _err "cc -static failed" ;;
	esac
	strip -s graftcp
	_cd local
	case "${BUILD_ARCH}" in
		*x86|i486*|i586*|i686*) _goarch="386" ;;
		*x64|x86_64*) _goarch="amd64" ;;
		*) _err "unknown arch: ${BUILD_ARCH}" ;;
	esac
	CC=/bin/cc GOARCH="${_goarch}" CGO_ENABLED=1 go build -ldflags "-s -w -extldflags=-static" -tags netgo ./cmd/graftcp-local || _err "go build graftcp-local failed"
	CC=/bin/cc GOARCH="${_goarch}" CGO_ENABLED=1 go build -ldflags "-s -w -extldflags=-static" -tags netgo ./cmd/mgraftcp || _err "go build mgraftcp failed"
	_cd ..
	_msg "installing ${_name}"
	mkdir -p "${_out}/bin"
	cp graftcp "${_out}/bin" || _err "cp"
	cp local/graftcp-local "${_out}/bin" || _err "cp"
	cp local/mgraftcp "${_out}/bin" || _err "cp"
	"${_out}/bin/graftcp" -V
}
