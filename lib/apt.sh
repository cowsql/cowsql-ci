export DEBIAN_FRONTEND=noninteractive

apt_update() {
    while :; do
        sudo apt-get update -qq && break
        sleep 10
    done
}

apt_install() {
    sudo apt-get install -qq -y "${@}"
}

apt_remove() {
    sudo apt-get purge -qq -y "${@}" > /dev/null 2>&1 || true
}
