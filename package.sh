#!/usr/bin/env bash

increment_version ()
{
    declare -a part=( ${1//\./ } )
    declare    new
    declare -i carry=1

    for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
        len=${#part[CNTR]}
        new=$((part[CNTR]+carry))
        [ ${#new} -gt $len ] && carry=1 || carry=0
        [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
    done
    new="${part[*]}"
    echo "${new// /.}"
}

for doc_name in `ls -d */`
do
    cd $doc_name && rm -rf *.docset/ && dashing build
    docset_dir_name=`ls -d *docset/`
    docset_name=${docset_dir_name%$'.docset/'}
    if [ -d "$docset_dir_name" ]; then
        rm "$docset_name.tgz"
        tar --exclude='.DS_Store' --exclude="$docset_name.xml" --exclude="$docset_name.tgz" -cvzf "$docset_name.tgz" "${docset_dir_name}"
        if [ ! -e "$docset_name.xml" ]; then
            echo "<entry><version>1.0</version><url>http://codepiano.github.io/dash/docset/$docset_name.tgz</url></entry>" > "$docset_name.xml"
        else
            version=`cat "$docset_name.xml" | grep -Eo 'version>([^<]+)' | cut -d '>' -f 2`
            bump_version=$(increment_version $version)
            echo "<entry><version>$bump_version</version><url>http://codepiano.github.io/dash/docset/$docset_name.tgz</url></entry>" > "$docset_name.xml"
        fi
    fi
    cd ..
done

