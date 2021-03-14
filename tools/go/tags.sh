#!/bin/sh

TAG_FILE=${1}
TAG_DIRS=${2}

tab="$(printf '\t')"

cat > ${TAG_FILE} <<EOF
!_TAG_FILE_FORMAT${tab}2${tab}/extended format; --format=1 will not append ;" to lines/
!_TAG_FILE_SORTED${tab}1${tab}/0=unsorted, 1=sorted, 2=foldcase/
!_TAG_PROGRAM_AUTHOR${tab}Darren Hiebert${tab}/dhiebert@users.sourceforge.net/
!_TAG_PROGRAM_NAME${tab}Exuberant Ctags${tab}//
!_TAG_PROGRAM_URL${tab}http://ctags.sourceforge.net${tab}/official site/
!_TAG_PROGRAM_VERSION${tab}5.8${tab}//
EOF

export LC_COLLATE=C
ctags --languages=Go -f - --excmd=number -R ${TAG_DIRS} | sed "s/^\(\w\+\)\t\+\([a-zA-Z0-9_\.\/]\+\)\/\([a-zA-Z0-9_]\+\)\.go/\3.\1\t\2\/\3.go\t/" | sort >> ${TAG_FILE}

