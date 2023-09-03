. ../lib/setup.sh

testbed=
version=

cmd_raft_benchmark() {
    cmd=raft-benchmark
    if [ "${version}" = "local" ]; then
        cmd=$(get raft path)/tools/$cmd
    fi
    if grep -q isolcpus /proc/cmdline; then
        cmd="taskset --cpu-list 3 ${cmd}"
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

block_driver_name() {
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

    echo $driver
}

benchmark_disk_target() {
    tag=$1
    target=$2
    args="disk -d ${target}"

    size=$(get benchmark-disk size)
    if [ -n "${size}" ]; then
        args="${args} -s ${size}"
    fi

    for buffer in $(get benchmark-disk buffer); do
        maybe_bencher_run --project raft --testbed "${tag}" \
                          "sudo $(cmd_raft_benchmark) ${args} -b ${buffer}"
    done
}

benchmark_disk() {
    for storage in $(get benchmark-disk storage); do
        unmount=no

        if echo "${storage}" | grep -qe ^/dev; then
            device=$(echo "${storage}" | cut -f 1 -d :)
            filesystem=$(echo "${storage}" | cut -f 2 -d :)
            driver=$(block_driver_name "${device}")
            tag="${testbed}-${driver}-${filesystem}"

            setup_device "${device}"
            if [ "${filesystem}" = "raw" ]; then
                target="${device}"
            else
                setup_filesystem "${device}" "${filesystem}" /mnt
                target=/mnt
                unmount=yes
            fi
        else
            tag="${testbed}"
            target="${storage}"
        fi

        benchmark_disk_target "${tag}" "${target}"

        if [ "${unmount}" = "yes" ]; then
            sudo umount "${target}"
        fi
    done
}
