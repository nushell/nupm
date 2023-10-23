#!/usr/bin/env bash

arch="$1"
ext="$2"
nu="$3"

tarball=$(\
    curl -L https://api.github.com/repos/nushell/nightly/releases \
        | jq 'sort_by(.published_at) | reverse | .[0].assets'\
        | jq ".[] | select(.name | test(\"$arch.$ext\")) | {name, browser_download_url}"\
)
name=$(echo $tarball | jq '.name' | tr -d '"' | sed "s/.$ext$//")
url=$(echo $tarball | jq '.browser_download_url' | tr -d '"')

curl -fLo $name $url

if [ "$ext" = "tar.gz" ]; then
    tar xvf $name --directory /tmp
elif [ "$ext" = "zip" ]; then
    unzip $name -d "/tmp/$name"
fi
cp "/tmp/$name/$nu" "$HOME/$nu"
