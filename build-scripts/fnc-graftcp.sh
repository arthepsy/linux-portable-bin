#!/bin/sh

# shellcheck disable=SC2120
_build_musl_graftcp() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="graftcp-${GRAFTCP_VERSION}"
	_msg "downloading ${_name}"
	mkdir -p "${_name}"
	cd "${_name}"
	git init || _err "git init failed"
	git remote add origin "https://github.com/hmgle/graftcp" || _err "git remote failed"
	git fetch --depth 1 origin "${GRAFTCP_VERSION}" || _err "git fetch failed"
	git checkout FETCH_HEAD || _err "git checkout failed"
	_msg "building ${_name}"
	CC=/bin/cc make || _err "make"
	_msg "building static ${_name}"
	/bin/cc -static -fPIC main.o graftcp.o util.o string-set.o conf.o -o graftcp || _err "cc -static failed"
	strip -s graftcp
	cd local
	go build -ldflags "-s -w -extldflags=-static" -tags netgo ./cmd/graftcp-local || _err "go build graftcp-local failed"
	go build -ldflags "-s -w -extldflags=-static" -tags netgo ./cmd/mgraftcp || _err "go build mgraftcp failed"
	cd ..
	_msg "installing ${_name}"
	mkdir -p "${_out}/bin"
	cp graftcp "${_out}/bin" || _err "cp"
	cp local/graftcp-local "${_out}/bin" || _err "cp"
	cp local/mgraftcp "${_out}/bin" || _err "cp"
	"${_out}/bin/graftcp" -V
}
