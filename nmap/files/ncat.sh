#!/bin/sh
_cdir=$(cd -- "$(dirname "$0")" && pwd)
case $@ in
	*--ssl-trustfile*) _ca=0 ;;
	*--ssl*) _ca=1 ;;
	*) _ca=0 ;;
esac
if [ $_ca -eq 1 ]; then "${_cdir}/ncat" --ssl-trustfile "${_cdir}/ncat-data/ca-bundle.crt" $@; else "${_cdir}/ncat" $@; fi
