#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021~ https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021~ https://github.com/ophub/amlogic-s9xxx-openwrt
# Copyright (C) 2021~ https://downloads.openwrt.org/releases
# Copyright (C) 2023~ https://downloads.immortalwrt.org/releases
#
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./config-openwrt/imagebuilder/imagebuilder.sh <source:branch>
#          ./config-openwrt/imagebuilder/imagebuilder.sh openwrt:21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_config           : Add custom config
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config-openwrt/imagebuilder/files"
custom_config_file="${make_path}/config-openwrt/imagebuilder/config"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Downloading imagebuilder files
    if [[ "${op_sourse}" == "openwrt" ]]; then
        download_file="https://downloads.openwrt.org/releases/${op_branch}/targets/armvirt/64/openwrt-imagebuilder-${op_branch}-armvirt-64.Linux-x86_64.tar.xz"
    else
        download_file="https://downloads.immortalwrt.org/releases/${op_branch}/targets/armvirt/64/immortalwrt-imagebuilder-${op_branch}-armvirt-64.Linux-x86_64.tar.xz"
    fi
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf *-imagebuilder-* && sync && rm -f *-imagebuilder-*.tar.xz
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adjusting .config file settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom packages..."

    # Create a [ packages ] directory
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-amlogic
    amlogic_api="https://api.github.com/repos/ophub/luci-app-amlogic/releases"
    #
    amlogic_file="luci-app-amlogic"
    amlogic_file_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_name}.*.ipk" | head -n 1)"
    wget ${amlogic_file_down} -q -P packages
    [[ "${?}" -eq "0" ]] || error_msg "[ ${amlogic_file} ] download failed!"
    echo -e "${INFO} The [ ${amlogic_file} ] is downloaded successfully."
    #
    amlogic_i18n="luci-i18n-amlogic"
    amlogic_i18n_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_i18n}.*.ipk" | head -n 1)"
    wget ${amlogic_i18n_down} -q -P packages
    [[ "${?}" -eq "0" ]] || error_msg "[ ${amlogic_i18n} ] download failed!"
    echo -e "${INFO} The [ ${amlogic_i18n} ] is downloaded successfully."

    # Download other luci-app-xxx
    # ......
    # Argon theme
    wget https://github.com/jerrykuku/luci-theme-argon/releases/download/v2.3/luci-theme-argon_2.3_all.ipk -q -P packages
    wget https://github.com/jerrykuku/luci-app-argon-config/releases/download/v0.9/luci-app-argon-config_0.9_all.ipk -q -P packages

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom packages, lib, theme, app and i18n, etc.
custom_config() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom config..."

    config_list=""
    if [[ -s "${custom_config_file}" ]]; then
        config_list="$(cat ${custom_config_file} 2>/dev/null | grep -E "^CONFIG_PACKAGE_.*=y" | sed -e 's/CONFIG_PACKAGE_//g' -e 's/=y//g' -e 's/[ ][ ]*//g' | tr '\n' ' ')"
        echo -e "${INFO} Custom config list: \n$(echo "${config_list}" | tr ' ' '\n')"
    else
        echo -e "${INFO} No custom config was added."
    fi
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom files..."

    if [[ -d "${custom_files_path}" ]]; then
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -l 2>/dev/null)"
    else
        echo -e "${INFO} No customized files were added."
    fi
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start building OpenWrt with Image Builder..."

    # Selecting default packages, lib, theme, app and i18n, etc.
    # sorting by https://build.moz.one
    my_packages="\
        acpid attr base-files bash bc bind-server blkid block-mount blockd bsdtar \
        btrfs-progs busybox bzip2 cgi-io chattr comgt comgt-ncm containerd coremark \
        coreutils coreutils-base64 coreutils-nohup coreutils-truncate curl \
        dosfstools dumpe2fs e2freefrag e2fsprogs exfat-mkfs \
        f2fs-tools f2fsck fdisk gawk getopt gzip hostapd-common iconv iw iwinfo jq jshn \
        kmod-brcmfmac kmod-brcmutil kmod-cfg80211 kmod-mac80211 libjson-script \
        liblucihttp liblucihttp-lua libnetwork losetup lsattr lsblk lscpu mkf2fs \
        mount-utils openssl-util parted perl-http-date perlbase-file perlbase-getopt \
        perlbase-time perlbase-unicode perlbase-utf8 pigz ppp ppp-mod-pppoe \
        proto-bonding pv rename resize2fs runc subversion-client subversion-libs tar \
        tini ttyd tune2fs uclient-fetch uhttpd uhttpd-mod-ubus unzip uqmi usb-modeswitch \
        uuidgen wget-ssl whereis which wpad-basic wwan xfs-fsck xfs-mkfs xz \
        xz-utils ziptool zoneinfo-asia zoneinfo-core zstd \
        \
        luci luci-base luci-compat luci-i18n-base-en luci-i18n-base-zh-cn luci-lib-base  \
        luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio  \
        luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system  \
        luci-proto-3g luci-proto-bonding luci-proto-ipip luci-proto-ipv6 luci-proto-ncm  \
        luci-proto-openconnect luci-proto-ppp luci-proto-qmi luci-proto-relay luci-proto-wireguard  \
        \
        luci-app-amlogic luci-i18n-amlogic-zh-cn \
        \
        luci-theme-argon luci-app-argon-config \
        \
        luci-app-ddns luci-app-nft-qos luci-app-upnp \
        luci-app-wireguard luci-app-wol tailscale tailscaled eoip wireguard-tools \
        acpid attr base-files bash bc bind-host bind-libs bind-server blkid block-mount blockd brcmfmac-firmware-usb bsdtar btrfs-progs busybox bzip2 ca-bundle cgi-io chat chattr comgt comgt-ncm containerd coremark coreutils coreutils-base64 coreutils-nohup coreutils-truncate curl ddns-scripts ddns-scripts-services dnsmasq dosfstools dropbear dumpe2fs e2freefrag e2fsprogs eoip etherwake ethtool exfat-mkfs f2fs-tools f2fsck fdisk firewall4 fstools fwtool gawk getopt getrandom gzip hostapd-common htop iconv ip6tables-nft iperf3 ipip iptables-nft iw iwinfo jansson4 jq jshn jsonfilter kernel kmod-bonding kmod-brcmfmac kmod-brcmutil kmod-cfg80211 kmod-crypto-acompress kmod-crypto-aead kmod-crypto-ccm kmod-crypto-cmac kmod-crypto-crc32c kmod-crypto-ctr kmod-crypto-gcm kmod-crypto-gf128 kmod-crypto-ghash kmod-crypto-hash kmod-crypto-hmac kmod-crypto-kpp kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-crypto-manager kmod-crypto-null kmod-crypto-rng kmod-crypto-seqiv kmod-crypto-sha256 kmod-fs-autofs4 kmod-fs-btrfs kmod-input-core kmod-input-evdev kmod-ip6tables kmod-ipip kmod-ipt-core kmod-ipt-ipset kmod-iptunnel kmod-iptunnel4 kmod-lib-crc-ccitt kmod-lib-crc32c kmod-lib-lzo kmod-lib-raid6 kmod-lib-xor kmod-lib-zlib-deflate kmod-lib-zlib-inflate kmod-lib-zstd kmod-mac80211 kmod-mii kmod-nf-conntrack kmod-nf-conntrack-netlink kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-log kmod-nf-log6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nft-bridge kmod-nft-compat kmod-nft-core kmod-nft-fib kmod-nft-nat kmod-nft-netdev kmod-nft-offload kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-net kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-huawei-cdc-ncm kmod-usb-net-qmi-wwan kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan kmod-usb-wdm kmod-wireguard libapr libaprutil libarchive libatomic1 libattr libblkid1 libblobmsg-json20220515 libbz2-1.0 libc libcap libcap-ng libcharset1 libcomerr0 libcurl4 libexpat libext2fs2 libf2fs6 libfdisk1 libffi libgcc1 libgdbm libgmp10 libgnutls libiconv-full2 libiptext-nft0 libiptext0 libiptext6-0 libiwinfo-data libiwinfo-lua libiwinfo20210430 libjson-c5 libjson-script20220515 libltdl7 liblua5.1.5 liblucihttp-lua liblucihttp0 liblzma liblzo2 libmagic libmbedtls12 libmnl0 libmount1 libncurses6 libnetfilter-conntrack3 libnettle8 libnetwork libnfnetlink0 libnftnl11 libnghttp2-14 libnl-tiny1 libopenssl-conf libopenssl1.1 libparted libpcap1 libpcre libpthread libpython3-3.10 libreadline8 librt libseccomp libsmartcols1 libsqlite3-0 libss2 libtasn1 libubox20220515 libubus-lua libubus20220601 libuci-lua libuci20130104 libuclient20201210 libucode20220812 libusb-1.0-0 libustream-wolfssl20201210 libuuid1 libuv1 libwebsockets-full libwolfssl5.5.4.ee39414e libxml2 libxtables12 libzip-openssl libzstd logd losetup lsattr lsblk lscpu lua luci luci-app-amlogic \
        luci-app-argon-config luci-app-ddns luci-app-firewall luci-app-nft-qos luci-app-opkg luci-app-upnp luci-app-wireguard luci-app-wol luci-base luci-compat luci-i18n-amlogic-zh-cn luci-i18n-base-en luci-i18n-base-zh-cn luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-3g luci-proto-bonding luci-proto-ipip luci-proto-ipv6 luci-proto-ncm luci-proto-openconnect luci-proto-ppp luci-proto-qmi luci-proto-relay luci-proto-wireguard luci-theme-argon luci-theme-bootstrap miniupnpd-nftables mkf2fs mount-utils mtd netifd nft-qos nftables-json odhcp6c odhcpd-ipv6only openconnect openssh-sftp-server openssl-util openwrt-keyring opkg parted perl perl-http-date perlbase-base perlbase-bytes perlbase-charnames perlbase-class perlbase-config perlbase-cwd perlbase-dynaloader perlbase-errno perlbase-essential perlbase-fcntl perlbase-file perlbase-filehandle perlbase-getopt perlbase-i18n perlbase-integer perlbase-io perlbase-list perlbase-locale perlbase-params perlbase-posix perlbase-re perlbase-scalar perlbase-selectsaver perlbase-socket perlbase-symbol perlbase-tie perlbase-time perlbase-unicode perlbase-unicore perlbase-utf8 perlbase-xsloader pigz ppp ppp-mod-pppoe procd procd-seccomp procd-ujail proto-bonding pv python3 python3-asyncio python3-base python3-cgi python3-cgitb python3-codecs python3-ctypes python3-dbm python3-decimal python3-distutils python3-email python3-light python3-logging python3-lzma python3-multiprocessing python3-ncurses python3-openssl python3-pydoc python3-readline python3-sqlite3 python3-unittest python3-urllib python3-uuid python3-xml relayd rename resize2fs resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns runc subversion-client subversion-libs tailscale tailscaled tar tcpdump terminfo tini ttyd tune2fs ubox ubus ubusd uci uclient-fetch ucode ucode-mod-fs ucode-mod-ubus ucode-mod-uci uhttpd uhttpd-mod-ubus unixodbc unzip uqmi urandom-seed urngd usb-modeswitch usign uuidgen vim vpnc-scripts wget-ssl whereis which wireguard-tools wireless-regdb wpad-basic wwan xfs-fsck xfs-mkfs xtables-nft xz xz-utils ziptool zlib zoneinfo-asia zoneinfo-core zstd \
        ${config_list} \
        "

    # Rebuild firmware
    make image PROFILE="Default" PACKAGES="${my_packages}" FILES="files"

    sync && sleep 3
    echo -e "${INFO} [ openwrt/bin/targets/armvirt/64 ] directory status: $(ls bin/targets/*/* -l 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} openwrt:22.03.3 ]"
[[ "${1}" =~ ^[a-z]{3,}:[0-9]+ ]] || error_msg "Incoming parameter format <source:branch>: openwrt:22.03.3"
op_sourse="${1%:*}"
op_branch="${1#*:}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild Source: [ ${op_sourse} ], Branch: [ ${op_branch} ]"
echo -e "${INFO} Server space usage before starting to compile: \n$(df -hT ${make_path}) \n"
#
# Perform related operations
download_imagebuilder
adjust_settings
custom_packages
custom_config
custom_files
rebuild_firmware
#
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait
