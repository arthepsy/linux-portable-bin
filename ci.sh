#!/bin/sh
_cdir=$(cd -- "$(dirname "$0")" && pwd)

_fail() {
	if [ "$1" -ne 0 ]; then
		echo "FAIL."
		if [ -e "build.log" ]; then
			cat "build.log"
		fi
		exit 1
	fi
}


cd "${_cdir}/masscan" || exit 1
for _arch in x86 x64; do
	./run.sh build "${_arch}" head > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" head; _fail $?
	./run.sh build "${_arch}" > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}"; _fail $?
done
cd "${_cdir}/socat" || exit 1
for _arch in x86 x64; do
	./run.sh build "${_arch}" > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}"; _fail $?
	./run.sh build "${_arch}" "" weak-ssl > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" "" weak-ssl; _fail $?
done
cd "${_cdir}/nmap" || exit 1
for _arch in x86 x64; do
	./run.sh build "${_arch}" head bad-ssl > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" head bad-ssl; _fail $?
	./run.sh build "${_arch}" head weak-ssl > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" head weak-ssl; _fail $?
	./run.sh build "${_arch}" "" bad-ssl > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" "" bad-ssl; _fail $?
	./run.sh build "${_arch}" "" weak-ssl > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" "" weak-ssl; _fail $?
done
cd "${_cdir}/openssl" || exit 1
	./run.sh build "${_arch}" "1.0.2-bad" zlib > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" "1.0.2-bad" zlib; _fail $?
	./run.sh build "${_arch}" "" zlib weak-ssl > build.log 2>&1; _fail $?
	./run.sh pack  "${_arch}" "" zlib weak-ssl; _fail $?
cd "${_cdir}" || exit 1

