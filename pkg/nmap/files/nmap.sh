#!/bin/sh
_cdir=$(cd -- "$(dirname "$0")" && pwd)
env NMAPDIR="${_cdir}/nmap-data" "${_cdir}/nmap" $@
