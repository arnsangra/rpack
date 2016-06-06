#!/bin/bash

PRGM_NAME="rpack"
REP_LOC="$HOME/repositories"
BUILD_PCKGS_DIR="$HOME/build-packages"
OS=`uname`

MYTMPDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

# deletes the temp directory
#function cleanup { rm -rf "$MYTMPDIR" echo "Deleted temp working directory $MYTMPDIR" }

# register the cleanup function to be called on the EXIT signal
#trap cleanup EXIT

if [[ $OS != 'Darwin' ]]; then
    LIB_PATH="/usr/local/lib/R/site-library"
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

    cd $MYTMPDIR
    PCK_PATH="$REP_LOC/$1"
    if [[ ! -d $PCK_PATH ]]; then
        printf "%s\n" "Could not find package source directory in $REP_LOC"

        if [[ -n "$REP_ALT_LOC" ]]; then
            printf "%s\n" "Attempting using alternative path $REP_ALT_LOC"
            PCK_PATH="$REP_ALT_LOC/$1"
            if [[ ! -d $PCK_PATH ]]; then
                printf "%s\n" "Could not find package in alternative source directory"
                exit 1
            fi
        else    # no luck in alternative loc.
            printf "%s\n" 'No alternative path found in "$REP_ALT_LOC" environment variable, exiting...'
            exit 1
        fi
    fi

    printf "%s\n" "$1 R package found in $PCK_PATH"

    PCK_NEW_VERSION=`grep -i version $PCK_PATH/DESCRIPTION | egrep -o "[[:digit:]](.?[[:digit:]])+"`
    BUILD_FILE="$PCK_NAME"'_'"$PCK_NEW_VERSION.tar.gz"
    BUILD_FILE_PATH="$MYTMPDIR/$BUILD_FILE"
    
    printf "%s\n" "Running R install commands through sudo..."
    sudo R CMD REMOVE $PCK_NAME
    sudo R CMD build $PCK_PATH
    sudo R CMD INSTALL -l $LIB_PATH "./$BUILD_FILE"

    if [[ $keep -ne 1 ]]; then
        rm -vf $BUILD_FILE
    else
        if [[ ! -d $HOME/build-packages ]]; then
            printf "%s\n" "'build-packages' folder does not exist... creating it"
            mkdir -p $HOME/build-packages
        fi
        mv "$BUILD_FILE_PATH" "$HOME/build-packages/$BUILD_FILE"
        printf "%s\n" "Backup copy of installed package kept in $BUILD_PCKGS_DIR"
    fi
    cd $HOME
    rm -rf $MYTMPDIR
fi

