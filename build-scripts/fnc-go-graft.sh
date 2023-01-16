#!/bin/sh

# shellcheck disable=SC2120
_build_musl_go_graft() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="go-graft-${GO_GRAFT_VERSION}"
	_msg "downloading ${_name}"
	if [ "${GO_GRAFT_VERSION}" == "head" ]; then
		git clone --depth 1 "https://github.com/mzz2017/gg" "${_name}" || _err "git clone failed"
		_cd "${_name}"
	else
		mkdir -p "${_name}"
		_cd "${_name}"
		git init || _err "git init failed"
		git remote add origin "https://github.com/mzz2017/gg" || _err "git remote failed"
		git fetch --depth 1 origin "v${GO_GRAFT_VERSION}" || _err "git fetch failed"
		git checkout FETCH_HEAD || _err "git checkout failed"
	fi
	_msg "building ${_name}"
	case "${BUILD_ARCH}" in
		*x86|i486*|i586*|i686*) _goarch="386" ;;
		*x64|x86_64*) _goarch="amd64" ;;
		*) _err "unknown arch: ${BUILD_ARCH}" ;;
	esac
	GOARCH="${_goarch}" CGO_ENABLED=0 go build -v -o gg -trimpath -ldflags "-X github.com/mzz2017/gg/cmd.Version=${GO_GRAFT_VERSION} -s -w -buildid=" . || _err "go build failed"
	_msg "minimizing ${_name}"
	upx gg || "upx failed"
	_msg "installing ${_name}"
	mkdir -p "${_out}/bin"
	cp  gg "${_out}/bin" || _err "cp"
	"${_out}/bin/gg" --version || _err "gg version failed"
}
