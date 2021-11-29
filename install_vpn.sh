#!/bin/bash
# Por Alan Queiroz - alan.queiroz@cronapp.io - 05/07/2021
# Script para instalar e configurar o cliente de VPN da FURB

BACKUP="/backup"
SCRIPTS="/scripts"
TESTE_VPN="/scripts/teste-vpn.sh"

NOME_USUARIO_VPN = ""
SENHA_USUARIO_VPN = ""

mkdir $SCRIPTS; mkdir $BACKUP

# Instalando o VPNC - VPN Cisco
amazon-linux-extras install epel
yum update -y
yum install vpnc -y

while [ -z $NOME_USUARIO_VPN ];
do 
     echo "INFORME O NOME DO USUARIO DA VPN"
     read NOME_USUARIO_VPN
done 

while [ -z $SENHA_USUARIO_VPN ];
do
     echo "INFORME A SENHA DO USUARIO DA VPN"
     read -s SENHA_USUARIO_VPN
done 

mv /etc/vpnc/default.conf $BACKUP
# Construindo arquivo de configuração
cat > /etc/vpnc/furb.conf << EOF
IPSec gateway ipsec.furb.br
IPSec ID ipsec
IPSec secret furb@vpn
IKE Authmode psk
Xauth username $NOME_USUARIO_VPN
Xauth password $SENHA_USUARIO_VPN
EOF

# Backup do script de start/stop do docker
cp /usr/lib/systemd/system/docker.service $BACKUP
sed -i "16i ExecStartPre=/scripts/teste-vpn.sh" /usr/lib/systemd/system/docker.service
systemctl daemon-reload

cat > $TESTE_VPN << EOF
#!/bin/bash
# Por Alan Queiroz - alan.queiroz@cronapp.io - 05/07/2021
# Script para testar a conectividade com a VPN da FURB
ENDERECO_VPN="hmlsga.furb.br"
DATA=$(date +'%Y-%m-%d_%H:%M:%S')
LOG="/var/log/teste-vpn.log"
echo "===========================" >> \$LOG
echo "\$DATA - ROTAS DE REDE" >> \$LOG
echo "" >> \$LOG
route -n >> \$LOG
echo "" >> \$LOG"
echo "\$DATA - TESTE DE PING PARA O ENDERECO $ENDERECO_VPN" >> $LOG
ping -c 10 \$ENDERECO_VPN >> $LOG
if [ \$? != 0 ]; then
echo "## \$DATA - DESCONECTADO DA VPN FURB ##" >> \$LOG
/usr/sbin/vpnc furb &
else
echo "*** \$DATA - CONECTADO NA VPN FURB ***" >> \$LOG
fi
echo "==========================="  >> \$LOG
EOF

chmod +x $SCRIPTS/*.sh

echo "*/5 * * * * root $TESTE_VPN" > /etc/crontab

echo "VPN FURB configurada"
