#!/usr/bin/env bash

os="$1"
github_env="${2:-$GITHUB_ENV}"

function save-env () {
    sed 's/^\s*//' >> $github_env
}

if [ "$os" = "Linux" ]; then
    echo "
        ARCH=x86_64-linux-gnu-full
        EXT=tar.gz
        NU_BIN=nu
        NUPM=$HOME/nupm
        CWD=$PWD
    " | save-env
elif [ "$os" = "Windows" ]; then
    echo "
        ARCH=x86_64-pc-windows-msvc
        EXT=zip
        NU_BIN=nu.exe
        NUPM=$(echo $HOME | tr '/' '\\' | sed 's/^\\\(.\)\\/\1:\\/')/nupm
        CWD=$(echo $PWD | tr '/' '\\' | sed 's/^\\\(.\)\\/\1:\\/')
    " | save-env
elif [ "$os" = "macOS" ]; then
    echo "
        ARCH=x86_64-apple-darwin
        EXT=tar.gz
        NU_BIN=nu
        NUPM=$HOME/nupm
        CWD=$PWD
    " | save-env
else
    echo "UNKNOWN OS \`$os\`"
    exit 1
fi

exit 0
