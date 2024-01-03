. ../lib/apt.sh

bencher_releases_url=https://api.github.com/repos/bencherdev/bencher/releases/latest

install_utils() {
    apt_install nvme-cli parted e2fsprogs curl wget

    # Install bencher
    curl -s $bencher_releases_url | \
        grep "browser_download_url.*-linux-$(uname -m|tr _ -)" | \
        cut -d : -f 2,3 | tr -d \" | wget -qi - -O /tmp/bencher

    chmod 755 /tmp/bencher
    sudo mv /tmp/bencher /usr/bin/bencher
}

install_cowsql() {
    version=$1

    case "${version}" in
        stable)
            ppa="ppa:cowsql/stable"
            ;;
        main)
            ppa="ppa:cowsql/main"
            ;;
        local)
            return
            ;;
        *)
            echo "unknown version ${version}"
            exit 1
            ;;
    esac

    packages=libraft-tools

    apt_remove $packages

    sudo add-apt-repository -y "${ppa}"

    apt_update
    apt_install $packages

    sudo add-apt-repository -r -y "${ppa}"
}
