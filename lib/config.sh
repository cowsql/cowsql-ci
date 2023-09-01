# get [--sections|<section> [key]]
get() {
    # shellcheck disable=SC2154
    file=$config

    if [ "$1" = "--sections" ]; then
        # shellcheck disable=SC2013
        for section in $(grep "^\[" "${file}" | sed -e "s#\[##g" | sed -e "s#\]##g"); do
            echo "${section}"
        done
        return 0
    fi

    section=$1
    key=
    [ $# -eq 2 ] && key=$2

    # https://stackoverflow.com/questions/49399984/parsing-ini-file-in-bash
    # This awk line turns ini sections => [section-name]key=value
    awk '/^\[/{prefix=$0; next} $1{print prefix $0}' "${file}" | while read -r line; do
        if case "$line" in \[$section\]*) true;; *) false;; esac; then
            value=$(echo "${line}" | sed -e "s/^\[$section\]//")
            if [ -z "$key" ]; then
                echo "${value}"
            else
                if case "$value" in $key=*) true;; *) false;; esac; then
                    echo "${value}" | sed -e "s/^$key=//"
                fi
            fi
        fi
    done
}
