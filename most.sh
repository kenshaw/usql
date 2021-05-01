#!/bin/bash

set -e

SRC=$(realpath $(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd))

NAME=usql
VER="$(date +%y.%m.%d)-dev"

PLATFORM=$(uname|sed -e 's/_.*//'|tr '[:upper:]' '[:lower:]'|sed -e 's/^\(msys\|mingw\).*/windows/')

TAGS=(
  most
  sqlite_icu
  sqlite_app_armor
  sqlite_fts5
  sqlite_introspect
  sqlite_json1
  sqlite_stat4
  sqlite_userauth
  sqlite_vtable
  osusergo
  netgo
  static_build
)

ICULIBS=$(pkg-config --libs icu-i18n)
case "$PLATFORM" in
  windows)
    if [ ! -e /mingw64/lib/libicui18n.a ]; then
      pushd /mingw64/lib &> /dev/null
      cmd /c 'mklink libicui18n.a libicuin.a'
      popd &> /dev/null
    fi
    ICULIBS=$(sed -e 's/-licuin //' <<< "$ICULIBS")
  ;;
esac

TAGS="${TAGS[@]}"

EXTLDFLAGS=(
  -fno-PIC
  -static
  $ICULIBS
  -ldl
)
EXTLDFLAGS="${EXTLDFLAGS[@]}"

LDFLAGS=(
  -s
  -w
  -X github.com/xo/usql/text.CommandName=$NAME
  -X github.com/xo/usql/text.CommandVersion=$VER
  -linkmode=external
  -extldflags \'$EXTLDFLAGS\'
  -extld g++
)
LDFLAGS="${LDFLAGS[@]}"

(set -x;
  go build \
    -tags="$TAGS" \
    -gccgoflags="all=-DU_STATIC_IMPLEMENTATION" \
    -buildmode=pie \
    -ldflags="$LDFLAGS" \
    $@
)
