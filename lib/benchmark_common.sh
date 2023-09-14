version=

cmd_raft_benchmark() {
    cmd=raft-benchmark
    if [ "${version}" = "local" ]; then
        cmd=$(get raft path)/tools/$cmd
    fi
    if [ "$(get global sudo)" = "yes" ]; then
        cmd="sudo ${cmd}"
    fi
    if grep -q isolcpus /proc/cmdline; then
        cpu="$(sed -e 's/.*isolcpus=//' /proc/cmdline | cut -f 1 -d ,)"
        cmd="taskset --cpu-list ${cpu} ${cmd}"
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
