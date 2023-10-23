#!/usr/bin/env bash

os="$1"

if [ "$os" = "Linux" ]; then
    env=$(echo "
        ARCH=x86_64-linux-gnu-full
        EXT=tar.gz
        NU_BIN=nu
        NUPM=$HOME/nupm
        CWD=$PWD
    ")
elif [ "$os" = "Windows" ]; then
    env=$(echo "
        ARCH=x86_64-pc-windows-msvc
        EXT=zip
        NU_BIN=nu.exe
        NUPM=$(echo $HOME | tr '/' '\\' | sed 's/^\\\(.\)\\/\1:\\/')/nupm
        CWD=$(echo $PWD | tr '/' '\\' | sed 's/^\\\(.\)\\/\1:\\/')
    ")
elif [ "$os" = "macOS" ]; then
    env=$(echo "
        ARCH=x86_64-apple-darwin
        EXT=tar.gz
        NU_BIN=nu
        NUPM=$HOME/nupm
        CWD=$PWD
    ")
else
    echo "UNKNOWN OS \`$os\`"
    exit 1
fi

echo $env | tr " " "\n"
exit 0
