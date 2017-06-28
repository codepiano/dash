#!/usr/bin/env bash
#  ________________________________
# / 需要安装 technosophos/dashing  \
# | 使用方法：                     |
# | 传递目录名则打包单个目录，     |
# \ 否则打包当前目录所有          /
#  -------------------------------
#       \   ^__^
#        \  (oo)\_______
#           (__)\       )\/\
#               ||----w |
#               ||     ||
# 提升版本号
increment_version()
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

# 重新打包
repack()
{
    # 移除旧的 build 目录，重新 build
    cd $1 && rm -rf *.docset/ && dashing build
    docset_dir_name=`ls -d *docset/`
    docset_name=${docset_dir_name%$'.docset/'}
    if [ -d "$docset_dir_name" ]; then
        # 移除旧的文档压缩包，生成新的压缩包
        rm "$docset_name.tgz"
        tar --exclude='.DS_Store' --exclude="$docset_name.xml" --exclude="$docset_name.tgz" -cvzf "$docset_name.tgz" "${docset_dir_name}"
        # 生成 xml 文件
        if [ ! -e "$docset_name.xml" ]; then
            # 第一次生成，默认版本号为 1.0
            echo "<entry><version>1.0</version><url>http://codepiano.github.io/dash/docset/$docset_name.tgz</url></entry>" > "$docset_name.xml"
        else
            # 非第一次生成，提升版本号
            version=`cat "$docset_name.xml" | grep -Eo 'version>([^<]+)' | cut -d '>' -f 2`
            bump_version=$(increment_version $version)
            echo "<entry><version>$bump_version</version><url>http://codepiano.github.io/dash/docset/$docset_name.tgz</url></entry>" > "$docset_name.xml"
        fi
    fi
    echo "repack [ $1 ] done!"
    cd ..
}

# 入口
if [ -n "$1" ];then
    # 传递目录名，打包单个目录
    if [ -d "$1" ]; then
        repack $1
    else
        echo "[ $1 ] is not a directory!"
    fi
else
    # 打包所有
    for doc_dir in `ls -d */`
    do
        repack $doc_dir
    done
fi
