# Shadowsocks-over-Cloak
> A script to automate the installation of Shadowsocks with the Cloak plugin on Debian 12 and Ubuntu 24.

This repository provides a script to automate the installation and configuration of Shadowsocks with the Cloak plugin on Debian 12 and Ubuntu 24 systems. Cloak obfuscates Shadowsocks traffic as legitimate HTTPS traffic, making it harder to detect and block.

A similar project, the [HirbodBehnam/Shadowsocks-Cloak-Installer](https://github.com/HirbodBehnam/Shadowsocks-Cloak-Installer), supports Debian 11 and Ubuntu 22. However, it doesn't support newer operating system releases. This script addresses this limitation by offering support for Debian 12 and Ubuntu 24, ensuring compatibility with the latest system updates.

During the installation process, the script performs the following actions:
- Updates system packages
- Downloads the latest releases of **Shadowsocks** and **Cloak**
- Generates cryptographic key pairs (public and private)
- Generates passwords
- Configures the installed software to run as system services on boot

Upon successful completion, the script outputs the following information to the console for administration:
- The private key
- The public key
- The Cloak administrator password
- The Shadowsocks password
- A Shadowsocks URI in the `ss://` format for easy configuration of client applications like **ShadowRocket**.

## Usage

To use the script, run the following command:

```bash
bash <(curl -sL https://raw.githubusercontent.com/rz6agx/Shadowsocks-over-Cloak/refs/heads/main/Cloak2-Installer.sh)
```

After running, the script will automatically install and configure Shadowsocks with the Cloak plugin. Follow the on-screen instructions to complete the setup.

### Explanation:

1. **Command `bash <(curl -sL URL)`**:
   - This is a convenient way to run the script directly from GitHub without cloning the repository.
   - `curl -sL` downloads the script, and `bash` executes it.

2. **On-screen instructions**:
   - Mentioned that the script is interactive and will prompt for necessary inputs.

## Example Shadowsocks Client Configuration

Here’s an example of a **Shadowsocks** client configuration file `config.json` with **Cloak** plugin settings:

```json
{
    "server": "your-server-ip",
    "server_port": 8388,
    "password": "your-password",
    "method": "aes-256-gcm",
    "plugin": "ck-client",
    "plugin_opts": "UID=your-admin-uid;ProxyMethod=shadowsocks;PublicKey=your-public-key;EncryptionMethod=plain;ServerName=www.bing.com"
}
```

### Explanation of fields:

- `server`: The IP address or domain name of your Shadowsocks server.
- `server_port`: The port on which Shadowsocks is running (default is 8388).
- `password`: The password for Shadowsocks authentication.
- `method`: The encryption method used by Shadowsocks (e.g., aes-256-gcm).
- `plugin`: Specifies the Cloak client plugin (ck-client).
- `plugin_opts`: Options for the Cloak plugin:
  - `UID`: The Admin UID generated during server setup.
  - `ProxyMethod`: The proxy method (shadowsocks in this case).
  - `PublicKey`: The public key generated by Cloak on the server.
  - `EncryptionMethod`: The encryption method for Shadowsocks.
  - `ServerName`: The domain name used to mask the traffic (e.g., www.bing.com).

## Acknowledgments

This project relies on the following amazing tools and technologies:

- **[Shadowsocks](https://shadowsocks.org/)** - A fast and secure proxy server.
- **[Cloak](https://github.com/cbeuw/Cloak)** - A plugin that masks proxy traffic as HTTPS.

Special thanks to the developers and contributors of these projects for making this possible!
