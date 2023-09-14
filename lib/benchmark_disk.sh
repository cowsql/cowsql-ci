. ../lib/setup.sh
. ../lib/benchmark_common.sh

testbed=
version=

benchmark_disk_run() {
    tag=$1
    target=$2
    args="disk -d ${target}"

    size=$(get benchmark-disk size)
    if [ -n "${size}" ]; then
        args="${args} -s ${size}"
    fi

    trace=$(get benchmark-disk trace)
    if [ -n "${trace}" ]; then
        args="${args} -t ${trace}"
    fi

    for buffer in $(get benchmark-disk buffer); do
        maybe_bencher_run --project raft --testbed "${tag}" \
                          "$(cmd_raft_benchmark) ${args} -b ${buffer}"
    done

    perf=$(get benchmark-disk perf)
    if [ "${perf}" = "yes" ]; then
        maybe_bencher_run --project raft --testbed "${tag}" \
                          "$(cmd_raft_benchmark) ${args} -b ${buffer} -p"
    fi

}

benchmark_disk() {
    for storage in $(get benchmark-disk storage); do
        # Setup
        if echo "${storage}" | grep -qe ^/dev; then
            device=$(echo "${storage}" | cut -f 1 -d :)
            filesystem=$(echo "${storage}" | cut -f 2 -d :)
            driver=$(block_driver_name "${device}")
            tag="${testbed}-${driver}-${filesystem}"

            setup_device "${device}"
            if [ "${filesystem}" = "raw" ]; then
                target="${device}"
                sudo chown "${USER}:${USER}" "${device}"
            else
                setup_filesystem "${device}" "${filesystem}" /mnt
                target=/mnt
                sudo chown "${USER}:${USER}" "${target}"
            fi
        else
            device="none"
            tag="${testbed}"
            target="${storage}"
        fi

        # Run
        benchmark_disk_run "${tag}" "${target}"

        # Teardown
        if [ "${device}" != "none" ]; then
            if [ "${filesystem}" = "raw" ]; then
                sudo chown "root:root" "${device}"
            else
                sudo umount "${target}"
            fi
        fi
    done
}
