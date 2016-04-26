#!/bin/bash

PRGM_NAME="rpack"
REP_LOC="$HOME/repositories"
OS=`uname`

if [[ $OS != 'Darwin' ]]; then
    LIB_PATH="--library=/usr/local/lib/R/site-library"
else
    LIB_PATH="/Library/Frameworks/R.framework/Versions/3.2/Resources/library"
fi


function usage {
    printf "%s\n" "Usage: $PRGM_NAME <package_name> [args]"
    printf "%15s\t%s\n" "-c:" "check package"
    printf "%15s\t%s\n" "-h:" "display this help and exit"
    printf "%15s\t%s\n" "-k:" "keep package build file after installation"
    printf "%15s\t%s\n" "-u:" "uninstall package"
}

if [[ -z "$1" ]]; then
    printf "%s\n" "Error: No package name was supplied"
    usage
    exit
else
    while getopts "chku" opt $2; do
        case $opt in
            c)
                check=1
                echo 'flag -c still not functional'
                ;;
            h)
                usage
                exit 0
                ;;
            k)
                keep=1
                ;;
            r)
                uninstall=1
                ;;
            \?)
                echo 'unknown option'
                usage
                exit 1;
                ;;
        esac
    done

    PCK_NAME=$1

    if [[ $uninstall -eq 1 ]]; then
        sudo R CMD REMOVE $PCK_NAME
        exit 0
    fi

    PCK_PATH="$REP_LOC/$1"
    if [[ ! -d $PCK_PATH ]]; then
        printf "%s\n" "Could not find package source directory in $REP_LOC"
        exit 1
    else

        PCK_NEW_VERSION=`grep -i version  $PCK_PATH/DESCRIPTION | grep -Eo [[:digit:]]\(.[[:digit:]]\)+`
        BUILD_FILE="$PCK_PATH"'_'"$PCK_NEW_VERSION.tar.gz"

        sudo R CMD REMOVE $PCK_NAME
        sudo R CMD build $PCK_PATH
        mv "`pwd`/$BUILD_FILE" "$REP_LOC/$BUILD_FILE"
        sudo R CMD INSTALL $LIB_PATH $BUILD_FILE

        if [[ $keep -ne 1 ]]; then
            rm -vf $BUILD_FILE
        fi
    fi
fi
