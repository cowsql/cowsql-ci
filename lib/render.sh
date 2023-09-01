# render <template>
render() {
    tmpfile="$(mktemp)"
    if ! [ -e "${1}" ]; then
        echo "render: $1 not found"
        exit 1
    fi
    ../bin/esh -o "${tmpfile}" -d "${1}" || ( rm -f "${tmpfile}"; echo "render: $1 is invalid"; exit 1 )
    # shellcheck disable=SC1090
    . "${tmpfile}"
    rm -f "${tmpfile}"
}
