#!/bin/sh

case "${1}" in
    "--list_tags")
        GREP_ARGS="-H ${2}"
        PRINT_FUNCTION="\4\t\1\t\2\tf\t\4\5"
        PRINT_VARIABLE="\4\t\1\t\2\t\3"
        FILTER="cat"
        ;;
    "--ctags")
        GREP_ARGS="-r ."
        PRINT_FUNCTION="\4\t\1\t\2\;\"\tf"
        PRINT_VARIABLE="\4\t\1\t\2\;\"\tv"
        FILTER="cat"
        tab="$(printf '\t')"
        echo "!_TAG_FILE_FORMAT${tab}2${tab}/extended format; --format=1 will not append ;\" to lines/"
        echo "!_TAG_FILE_SORTED${tab}1${tab}/0=unsorted, 1=sorted, 2=foldcase/"
        echo "!_TAG_PROGRAM_AUTHOR${tab}Darren Hiebert${tab}/dhiebert@users.sourceforge.net/"
        echo "!_TAG_PROGRAM_NAME${tab}Exuberant Ctags${tab}//"
        echo "!_TAG_PROGRAM_URL${tab}http://ctags.sourceforge.net${tab}/official site/"
        echo "!_TAG_PROGRAM_VERSION${tab}5.8${tab}//"
        ;;
    *)
        echo invalid arguments
        exit -1
        ;;
esac

LOCATION="^\([^:]\+\.vim\):\([0-9]\+\)"

TMP_FILE=$(mktemp /tmp/beryl.XXXXXX)

# listing functions
FUNCTION_DECL="fu\(nction\)\?!\?"
FUNCTION_NAME="\([^(]\+\)"
FUNCTION_ARGS="\([^(]\+\)"
grep -ne "^${FUNCTION_DECL}" ${GREP_ARGS} \
    | sed -ne "s|${LOCATION}:${FUNCTION_DECL}\s${FUNCTION_ARGS}\(.*\)$|${PRINT_FUNCTION}|p" \
    >> ${TMP_FILE}

VARIABLE_DECL="\s\+let\s\+"
VARIABLE_NAME="\([a-zA-Z0-9:_]\+\)"
grep -ne "${VARIABLE_DECL}" ${GREP_ARGS} \
    | sed -ne "s|${LOCATION}:${VARIABLE_DECL}${VARIABLE_NAME}\s*=\(.*\)|\3\t\1\t\2\tv\t\3|p" \
    >> ${TMP_FILE}

LC_COLLATE=C sort ${TMP_FILE}

rm ${TMP_FILE}

