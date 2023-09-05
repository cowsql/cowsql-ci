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
        cmd="taskset --cpu-list 3 ${cmd}"
    fi
    echo "${cmd}"
}

