#!/bin/sh

# [[  tagger  ]] -- l0xy@pm.me
#      utility to quickly work with extended *user* attributes
#      in order to provide "tag" like functionality

if [ "$DEBUG" ]; then
    set -x
fi

usage() {
echo "tagger v0.1 -- key/value file tagging utility

Usage: tag key[:value] file...
       tag {-d key} file...
       tag {-t key[:value]} [-v] [path...]
       tag {-v} [key] path...

  -d, --delete=key        delete key from file attributes 
  -t, --tagged=key        lists files with tagged with key
      --tagged=key:value  lists files with with tag key whose value is value
  -v, --values            list values, for use with -l
      --null=\"string\"   string to use with -v when key has no value
      --help              this help text
"
}

if command -v tput >/dev/null 2>&1; then
  if tput smul 2>/dev/null; then
    STYLE="$(tput smul)"
    STYLE_RESET="$(tput sgr0 2>/dev/null || echo '')"
  elif tput bold 2>/dev/null; then
    STYLE="$(tput bold)"
    STYLE_RESET="$(tput sgr0 2>/dev/null || echo '')"
  elif [ $(($(tput colors 2>/dev/null))) -ge 8 ]; then
    MAGENTA="$(tput setaf 5 2>/dev/null || echo '')"
    STYLE="$MAGENTA"
    STYLE_RESET="$(tput sgr0 2>/dev/null || echo '')"
  fi
fi

query () {
    if [ "$PRINT_VALUES" ]; then
    getfattr --absolute-names -Rhd ${QUERY_TAG:+-m "^user.$QUERY_TAG"} "${QUERY_PATH:-$(pwd)}" 2>/dev/null \
        | awk -v null_value="${NULL_VALUE:--}" '
        BEGIN { 
            RS=""
            FS="\n"
            tag_index=0
        }{
            sub(/^#\sfile:\s/,"", $1)
            for (i = 2; i <= NF; i++) {
                split($i, kv, "=")
                sub(/user./, "", kv[1])
                gsub(/"/, "", kv[2])
                if (kv[2] ~ /^""$/ ) {
                    kv[2] = null_value
                }
                array[tag_index,0] = kv[1]
                array[tag_index,1] = kv[2]
                array[tag_index,2] = $1

                tag_index++
            }
        } 
        END {
            maxlen_tag = 0
            maxlen_value = 0
            maxlen_path = 0

            for (i = 0; i <= tag_index; i++) {
                if (length(array[i,0]) > maxlen_tag) {
                    maxlen_tag = length(array[i,0])
                }
                if (length(array[i,1]) > maxlen_value) {
                    maxlen_value = length(array[i,1])
                }
                if (length(array[i,2]) > maxlen_path) {
                    maxlen_path = length(array[i,2])
                }
            }

            fmt=sprintf("%%-%ss\t%%-%ss\t%%-%ss\n", maxlen_tag, maxlen_value, maxlen_path)
            printf fmt, "TAG", "VALUE", "FILE"
            for (i = 0; i <= tag_index; i++) {
                printf fmt, array[i,0], array[i,1], array[i,2]
            }
    }' | \
      awk -v style="${STYLE}" -v no_style="${STYLE_RESET}" -v filter="${QUERY_VALUE}" '
            NR<2 { printf "%s%s%s\n", style, $0, no_style; next }
            { 
              if (filter) { if ($2 == filter ) print $0 | "sort" }
              else { print $0 | "sort" }
            }'

    else
      getfattr --absolute-names -Rh ${QUERY_TAG:+-m "^user.$QUERY_TAG"} "${QUERY_PATH:-$(pwd)}" 2>/dev/null \
        | awk -v null_value="${NULL_VALUE:--}" '
            BEGIN { 
            RS=""
            FS="\n"
            tag_index=0
        }{
            sub(/^#\sfile:\s/,"", $1)
            for (i = 2; i <= NF; i++) {
                sub(/user./, "", $i)
                sub(/"/, "", $i)
                array[tag_index,0] = $i
                array[tag_index,1] = $1
                
                tag_index++
            }
        } 
        END {
            maxlen_tag = 0
            maxlen_path = 0
            for (i = 0; i <= tag_index; i++) {
                if (length(array[i,0]) > maxlen_tag) {
                    maxlen_tag = length(array[i,0])
                }
                if (length(array[i,1]) > maxlen_path) {
                    maxlen_path = length(array[i,1])
                }
            }
            fmt=sprintf("%%-%ss\t%%-%ss\n", maxlen_tag, maxlen_path)
            printf fmt, "TAG", "FILE"
            printf ""
            for (i = 0; i <= tag_index; i++) {
                printf fmt, array[i,0], array[i,1]
            }
    }' | awk -v style="${STYLE}" -v no_style="${STYLE_RESET}" '
            NR<2 { printf "%s%s%s\n", style, $0, no_style; next } { print $0 | "sort" }'
    fi

}

modify () {
    if [ "$DELETE_TAG" ]; then
        if setfattr -x "user.$1" "$2"; then
            QUERY_PATH="$2" query
        else
            echo "Failed to delete tag."
            exit 1
        fi

    # KEY "if no colons in string..."
    elif [ "$(echo "$1" | tr -d ':')" = "$1" ]; then
        if setfattr -n "user.$1" "$2"; then
           QUERY_PATH="$2" query
        else
            echo "Failed to create tag."
            exit 1
        fi

    # KEY:VAL "if non-zero strings before & after (first) colon..."
    elif [ -n "${1#*:}" ] && [ -n "${1%%:*}" ]; then
        if setfattr -n "user.${1%%:*}" -v "${1#*:}" "$2"; then
            PRINT_VALUES=1 QUERY_PATH="$2" query
        else
            echo "Failed to create tag."
            exit 1
        fi

    else
       usage 

    fi
}

case $# in
    1)
        QUERY_PATH="$1" query
        ;;
    *)
        while [ "$#" -ne 0 ]; do
            case $1 in
                -t | --tagged )
                    shift
                    case "$1" in 
                      *:*)
                        QUERY_TAG="${1:+${1%%:*}}" 
                        QUERY_VALUE="${1#*:}"
                        PRINT_VALUES=1
                        ;;
                      *)
                        QUERY_TAG="$1"
                    esac
                    case "$2" in
                      -*)
                        pass
                        ;;
                      *)
                        QUERY_PATH="$2"
                        shift
                    esac
                    ;;
                -v | --values )
                    PRINT_VALUES=1
                    ;;
                -d | --delete )
                    DELETE_TAG=1
                    ;;
                *) 
                    if [ "$#" -eq 2 ]; then
                        modify "$@"
                        exit 0
                    else
                        usage
                        exit 1
                    fi
                    ;;
            esac
            shift
        done

        if [ "$PRINT_VALUES" ] || [ "$QUERY_TAG" ] || [ "$QUERY_PATH" ]; then
            query
        else 
            usage
            exit 1
        fi
esac
