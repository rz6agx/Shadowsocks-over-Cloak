# Shadowsocks-over-Cloak
> A script to automate the installation of Shadowsocks with Cloak plugin on Debian 12 and Ubuntu 24

On GitHub, you can find the [HirbodBehnam/Shadowsocks-Cloak-Installer project](https://github.com/HirbodBehnam/Shadowsocks-Cloak-Installer), which supports Debian, Ubuntu, and other distributions.

This repository provides a script to automate the installation and configuration of Shadowsocks with the Cloak plugin on Debian and Ubuntu systems. Cloak obfuscates Shadowsocks traffic as legitimate HTTPS traffic, making it more difficult to detect and block.

A similar project, [HirbodBehnam/Shadowsocks-Cloak-Installer project](https://github.com/HirbodBehnam/Shadowsocks-Cloak-Installer), exists. However, it has limitations in terms of supported operating system versions, primarily focusing on Debian 11 and Ubuntu 22. This script addresses this limitation by offering support for newer releases of Debian and Ubuntu, ensuring compatibility with the latest system updates.

During the installation process, the script performs the following actions: updates system packages, downloads the latest releases of **Shadowsocks** and **Cloak**, generates cryptographic key pairs (public and private), generates passwords, and configures the installed software to run as system services on boot. Upon successful completion, the script outputs the following information to the console for administration: the private key, the public key, the Cloak administrator password, the Shadowsocks password, and a Shadowsocks URI in the `ss://` format for easy configuration of client applications like **ShadowRocket**.
