testbed=
version=

cmd_raft_benchmark() {
    cmd=raft-benchmark
    if [ "${version}" = "local" ]; then
        cmd=$(get raft path)/tools/$cmd
    fi
    echo "${cmd}"
}

maybe_bencher_run() {
    token=$(get bencher token)
    if [ -n "${token}" ]; then
        branch=$version
        bencher run --token "${token}" --branch "${branch}" "$@"
    else
        # Do not send reports, only run the command given as last argument.
        # shellcheck disable=SC1083
        eval last=\${$#}
        # shellcheck disable=SC2154
        ${last}
    fi
}

benchmark_disk_raw() {
    device=$1
    buffer=$2
    maybe_bencher_run --project raft --testbed "${testbed}-${driver}-raw" \
                      "sudo $(cmd_raft_benchmark) disk -d ${device} -b ${buffer}"
}

benchmark_disk_filesystem() {
    filesystem=$1
    mountpoint=$2
    buffer=$3
    maybe_bencher_run --project raft --testbed "${testbed}-${driver}-${filesystem}" \
                      "sudo $(cmd_raft_benchmark) disk -d ${mountpoint} -b ${buffer}"
}

benchmark_disk() {
    device=${1}

    case $device in
        /dev/nvme*)
            driver=nvme
            ;;
        /dev/nullb*)
            driver=null
            ;;
        *)
            echo "unknown driver type for $device"
            exit 1
            ;;
    esac

    # Raw device benchmark
    for buffer in $(get benchmark-disk buffer); do
        benchmark_disk_raw "${device}" "${buffer}"
    done

    # File system benchmarks
    for filesystem in $(get benchmark-disk filesystem); do
        mountpoint=/mnt
        setup_filesystem "${device}" "${filesystem}" "${mountpoint}"
        for buffer in $(get benchmark-disk buffer); do
            benchmark_disk_filesystem "${filesystem}" "${mountpoint}" "${buffer}"
        done
        sudo umount /mnt
    done
}

benchmark() {
    for device in $(get global device); do
        benchmark_disk "${device}"
    done
}
