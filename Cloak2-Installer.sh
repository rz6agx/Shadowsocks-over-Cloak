#!/bin/bash

# Обновляем систему
apt-get update
apt-get upgrade -y

# Устанавливаем необходимые пакеты
apt-get install -y curl wget libssl-dev jq

# Устанавливаем ShadowSocks из официального репозитория
apt-get install -y shadowsocks-libev

# Определяем последнюю версию Cloak
CLOAK_VERSION=$(curl -s https://api.github.com/repos/cbeuw/Cloak/releases/latest | jq -r .tag_name | sed 's/v//')
if [ -z "$CLOAK_VERSION" ]; then
  echo "Не удалось определить последнюю версию Cloak. Использую версию 2.10.0."
  CLOAK_VERSION="2.10.0"
fi

# Загружаем файлы Cloak
wget -q https://github.com/cbeuw/Cloak/releases/download/v${CLOAK_VERSION}/ck-server-linux-amd64-v${CLOAK_VERSION} -O /usr/local/bin/ck-server
wget -q https://github.com/cbeuw/Cloak/releases/download/v${CLOAK_VERSION}/ck-client-linux-amd64-v${CLOAK_VERSION} -O /usr/local/bin/ck-client

# Проверяем успешность скачивания файлов
if [ ! -f /usr/local/bin/ck-server ] || [ ! -f /usr/local/bin/ck-client ]; then
    echo "Ошибка при загрузке файлов Cloak."
    exit 1
fi

# Устанавливаем Cloak
chmod +x /usr/local/bin/ck-server /usr/local/bin/ck-client

# Генерация ключей для Cloak
KEY_OUTPUT=$(/usr/local/bin/ck-server -k)

# Извлечение PublicKey и PrivateKey
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | awk -F',' '{print $1}')
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | awk -F',' '{print $2}')

# Проверка, что ключи успешно сгенерированы
if [ -z "$PUBLIC_KEY" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Ошибка при генерации ключей для Cloak."
  exit 1
fi

# Генерация AdminUID
ADMIN_UID=$(/usr/local/bin/ck-server -u)

# Проверка, что AdminUID успешно сгенерирован
if [ -z "$ADMIN_UID" ]; then
  echo "Ошибка при генерации AdminUID для Cloak."
  exit 1
fi

# Генерация пароля для ShadowSocks
SHADOWSOCKS_PASSWORD=$(head -c 16 /dev/urandom | base64)

# Создаем конфигурационный файл для Cloak
mkdir -p /etc/cloak
cat <<EOF > /etc/cloak/config.json
{
    "ProxyBook": {
        "shadowsocks": ["tcp", "127.0.0.1:8388"]
    },
    "BindAddr": [":443"],
    "BypassUID": [],
    "RedirAddr": "www.bing.com",
    "PrivateKey": "$PRIVATE_KEY",
    "AdminUID": "$ADMIN_UID",
    "DatabasePath": "/etc/cloak/userinfo.db"
}
EOF

# Проверяем успешность записи
if [ $? -ne 0 ]; then
  echo "Ошибка при создании конфигурационного файла для Cloak."
  exit 1
fi

# Создаем сервис для Cloak
cat <<EOF > /etc/systemd/system/cloak.service
[Unit]
Description=Cloak Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ck-server -c /etc/cloak/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Запускаем и включаем сервис Cloak
systemctl daemon-reload
systemctl enable --now cloak

if ! systemctl is-active --quiet cloak; then
  echo "Ошибка: сервис Cloak не запущен. Проверьте логи:"
  journalctl -u cloak.service
  exit 1
fi

# Настройка ShadowSocks
cat <<EOF > /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":8388,
    "password":"$SHADOWSOCKS_PASSWORD",
    "method":"aes-256-gcm",
    "timeout":300,
    "fast_open":false
}
EOF

# Запускаем и включаем сервис ShadowSocks
systemctl restart shadowsocks-libev
systemctl enable shadowsocks-libev

if ! systemctl is-active --quiet shadowsocks-libev; then
  echo "Ошибка: сервис ShadowSocks не запущен."
  exit 1
fi

# Получаем внешний IP-адрес сервера
SERVER_IP=$(curl -s --max-time 10 https://api.ipify.org)
if [ -z "$SERVER_IP" ]; then
  echo "Не удалось автоматически определить внешний IP-адрес сервера."
  read -p "Введите внешний IP-адрес сервера вручную: " SERVER_IP
fi

# Кодируем параметры ShadowSocks в base64
SHADOWSOCKS_BASE64=$(echo -n "aes-256-gcm:$SHADOWSOCKS_PASSWORD" | base64)

# Формируем параметры плагина Cloak
CLOAK_PLUGIN="ck-client;UID=$ADMIN_UID;ProxyMethod=shadowsocks;PublicKey=$PUBLIC_KEY;EncryptionMethod=plain;ServerName=www.bing.com"
CLOAK_PLUGIN_URLENCODED=$(echo -n "$CLOAK_PLUGIN" | jq -sRr @uri)

# Формируем ссылку для клиентов
CLIENT_LINK="ss://$SHADOWSOCKS_BASE64@$SERVER_IP:443?plugin=$CLOAK_PLUGIN_URLENCODED"

echo "Установка завершена!"
echo "AdminUID: $ADMIN_UID"
echo "PrivateKey: $PRIVATE_KEY"
echo "PublicKey: $PUBLIC_KEY"
echo "ShadowSocks Password: $SHADOWSOCKS_PASSWORD"
echo "Ссылка для клиентов: $CLIENT_LINK"