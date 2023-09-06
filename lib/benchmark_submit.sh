. ../lib/setup.sh
. ../lib/benchmark_common.sh

benchmark_submit_run() {
    tag=$1
    target=$2
    args="submit -d ${target}"

    for buffer in $(get benchmark-submit buffer); do
        maybe_bencher_run --project raft --testbed "${tag}" \
                          "$(cmd_raft_benchmark) ${args} -b ${buffer}"
    done
}

benchmark_submit() {
    for storage in $(get benchmark-submit storage); do
        # Setup
        if echo "${storage}" | grep -qe ^/dev; then
            device=$(echo "${storage}" | cut -f 1 -d :)
            filesystem=$(echo "${storage}" | cut -f 2 -d :)
            driver=$(block_driver_name "${device}")
            tag="${testbed}-${driver}-${filesystem}"
            target=/mnt

            setup_filesystem "${device}" "${filesystem}" /mnt
            sudo chown "${USER}:${USER}" "${target}"
        else
            device="none"
            tag="${testbed}"
            target="${storage}"
        fi

        # Run
        benchmark_submit_run "${tag}" "${target}"

        # Teardown
        if [ "${device}" != "none" ]; then
            sudo umount "${target}"
        fi
    done
}
