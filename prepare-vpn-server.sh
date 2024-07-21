#!/bin/bash

serverip=$(curl -s ipinfo.io/ip)

textcolor='\033[1;36m'
red='\033[1;31m'
clear='\033[0m'


### ВВОД ДАННЫХ ###
echo ""
echo ""

echo -e "${textcolor}ВНИМАНИЕ!${clear}"
echo "Перед запуском скрипта рекомендуется выполнить следующие действия:"
echo -e "1) Обновить систему командой ${textcolor}apt update && apt full-upgrade -y${clear}"
echo -e "2) Перезагрузить сервер командой ${textcolor}reboot${clear}"
echo -e "3) При наличии своего сайта отправить папку с его файлами в ${textcolor}/root${clear} директорию сервера"
echo ""
echo -e "Если это сделано, то нажмите ${textcolor}Enter${clear}, чтобы продолжить"
echo -e "В противном случае нажмите ${textcolor}Ctrl + C${clear} для завершения работы скрипта"
read BigRedButton
echo ""
echo "Введите новый номер порта SSH:"
read sshp
echo ""
while [ $sshp -eq 10443 ] || [ $sshp -eq 11443 ] || [ $sshp -eq 40000 ]
do
    echo -e "${red}Ошибка: порты 10443, 11443 и 40000 будут заняты Sing-Box и WARP${clear}"
    echo ""
    echo "Введите новый номер порта SSH:"
    read sshp
    echo ""
done
while [ $sshp -gt 65535 ]
do
    echo -e "${red}Ошибка: номер порта не может быть больше 65535${clear}"
    echo ""
    echo "Введите новый номер порта SSH:"
    read sshp
    echo ""
    while [ $sshp -eq 10443 ] || [ $sshp -eq 11443 ] || [ $sshp -eq 40000 ]
    do
        echo -e "${red}Ошибка: порты 10443, 11443 и 40000 будут заняты Sing-Box и WARP${clear}"
        echo ""
        echo "Введите новый номер порта SSH:"
        read sshp
        echo ""
    done
done
echo "Введите имя пользователя:"
read username
echo ""
echo "Введите пароль пользователя:"
read password
echo ""
echo "Введите часовой пояс для установки времени на сервере (например, Europe/Amsterdam):"
read timezone
echo ""
while [ ! -f /usr/share/zoneinfo/${timezone} ]
do
    echo -e "${red}Ошибка: введённого часового пояса не существует в /usr/share/zoneinfo, проверьте правильность написания${clear}"
    echo ""
    echo "Введите часовой пояс для установки времени на сервере (например, Europe/Amsterdam):"
    read timezone
    echo ""
done

echo ""
echo ""

timedatectl set-timezone ${timezone}


### BBR ###
if [[ ! "$(sysctl net.core.default_qdisc)" == *"= fq" ]]
then
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
fi

if [[ ! "$(sysctl net.ipv4.tcp_congestion_control)" == *"bbr" ]]
then
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
fi

sysctl -p
echo ""


### УСТАНОВКА ПАКЕТОВ ###
apt install sudo gnupg2 unattended-upgrades sed net-tools -y

### БЕЗОПАСНОСТЬ ###
useradd -m -s $(which bash) -G sudo ${username}
echo "${username}:${password}" | chpasswd

cat > /etc/ssh/sshd_config <<EOF
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

Port ${sshp}
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin no
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of "PermitRootLogin prohibit-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server
EOF

systemctl restart ssh.service

ufw allow ${sshp}/tcp
ufw allow 443/tcp
ufw allow 80/tcp
yes | ufw enable

echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades
systemctl restart unattended-upgrades

echo ""
echo ""
echo ""
echo -e "${textcolor}Если выше не возникло ошибок, то настройка завершена${clear}"
echo ""
echo -e "${textcolor}ВНИМАНИЕ!${clear}"
echo "Для повышения безопасности сервера рекомендуется выполнить следующие действия:"
echo -e "1) Отключиться от сервера ${textcolor}Ctrl + D${clear}"
echo -e "2) Если нет ключей SSH, то сгенерировать их на своём ПК командой ${textcolor}ssh-keygen -t rsa -b 4096${clear}"
echo -e "3) Отправить публичный ключ на сервер командой ${textcolor}ssh-copy-id -p ${sshp} ${username}@${serverip}${clear}"
echo -e "4) Подключиться к серверу ещё раз командой ${textcolor}ssh -p ${sshp} ${username}@${serverip}${clear}"
echo -e "5) Открыть конфиг sshd командой ${textcolor}sudo nano /etc/ssh/sshd_config${clear} и в PasswordAuthentication заменить yes на no"
echo -e "6) Перезапустить SSH командой ${textcolor}sudo systemctl restart ssh.service${clear}"
echo ""
