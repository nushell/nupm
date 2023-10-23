#!/usr/bin/env bash

tarball=$(\
    curl -L https://api.github.com/repos/nushell/nightly/releases \
        | jq 'sort_by(.published_at) | reverse | .[0].assets'\
        | jq '.[] | select(.name | test("${{ env.ARCH }}.${{ env.EXT }}")) | {name, browser_download_url}'\
)
name=$(echo $tarball | jq '.name' | tr -d '"' | sed 's/.${{ env.EXT }}$//')
url=$(echo $tarball | jq '.browser_download_url' | tr -d '"')

curl -fLo $name $url

if [ "${{ env.EXT }}" = "tar.gz" ]; then
    tar xvf $name --directory /tmp
elif [ "${{ env.EXT }}" = "zip" ]; then
    unzip $name -d "/tmp/$name"
fi
cp "/tmp/$name/${{ env.NU_BIN }}" "$HOME/${{ env.NU_BIN }}"
