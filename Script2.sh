#!/bin/sh
#-----------------------
User="{YOUR_LINUX_USERNAME_HERE}"

Domain="{YOUR_DOMAIN_HERE}"

VultrAPI="{YOUR_VULTR_API_KEY_HERE}"
#TO ENABLE API KEY 
#https://my.vultr.com/settings/#settingsapi

EmailID="{YOUR_EMAIL_SENDER_HERE}"
#For EmailID, you would enter "admin" if you want your phishing mail to be sent from "admin@example.com"

#-----------------------
export VULTR_API_KEY=$VultrAPI
Public_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

#-----------------------POSTFIX SETUP AND CONFIG

sudo DEBIAN_PRIORITY=low DEBIAN_FRONTEND=noninteractive apt install postfix -y
echo "root: "${User}"" | sudo tee -a /etc/aliases
sudo postconf -e 'home_mailbox= Maildir/'
sudo postconf -e 'virtual_alias_maps= hash:/etc/postfix/virtual'
echo ""${EmailID}"@"${Domain}" "${User}"" | sudo tee -a /etc/postfix/virtual
echo "admin@"${Domain}" "$User"" | sudo tee -a /etc/postfix/virtual
sudo postmap /etc/postfix/virtual
sudo systemctl restart postfix
sudo ufw allow Postfix
echo 'export MAIL=~/Maildir' | sudo tee -a /etc/bash.bashrc | sudo tee -a /etc/profile.d/mail.sh
source /etc/profile.d/mail.sh
sudo apt install s-nail
sudo bash -c 'echo "set emptystart" >> /etc/s-nail.rc'
sudo bash -c 'echo "set folder=Maildir" >> /etc/s-nail.rc'
sudo bash -c 'echo "set record=+sent" >> /etc/s-nail.rc'
echo 'init' | s-nail -s 'init' -Snorecord $User

#----------------------- SPF RECORD CONFIG

sudo apt install postfix-policyd-spf-python -y
sudo bash -c 'echo "policyd-spf  unix  -       n       n       -       0       spawn
    user=policyd-spf argv=/usr/bin/policyd-spf" >> /etc/postfix/master.cf'
sudo bash -c 'echo "policyd-spf_time_limit = 3600
smtpd_recipient_restrictions =
   permit_mynetworks,
   permit_sasl_authenticated,
   reject_unauth_destination,
   check_policy_service unix:private/policyd-spf" >> /etc/postfix/main.cf'
sudo systemctl restart postfix

#----------------- DKIM RECORD CONFIG

sudo apt install opendkim opendkim-tools -y
sudo gpasswd -a postfix opendkim
sudo sed -i -r 's/relaxed\/simple/simple/' /etc/opendkim.conf
sudo sed -i -r 's/\#Mode/Mode/' /etc/opendkim.conf
sudo sed -i -r 's/\#SubDomains/SubDomains/' /etc/opendkim.conf
sudo sed -i /etc/opendkim.conf -e '/SubDomains.*/a AutoRestart\t\tyes'
sudo sed -i /etc/opendkim.conf -e '/AutoRestart.*/a AutoRestartRate\t\t10/1M'
sudo sed -i /etc/opendkim.conf -e '/AutoRestartRate.*/a Background\t\tyes'
sudo sed -i /etc/opendkim.conf -e '/Background.*/a DNSTimeout\t\t5'
sudo sed -i /etc/opendkim.conf -e '/DNSTimeout.*/a SignatureAlgorithm\trsa-sha256'

sudo bash -c 'echo "#OpenDKIM user
# Remember to add user postfix to group opendkim
UserID             opendkim

# Map domains in From addresses to keys used to sign messages
KeyTable           refile:/etc/opendkim/key.table
SigningTable       refile:/etc/opendkim/signing.table

# Hosts to ignore when verifying signatures
ExternalIgnoreList  /etc/opendkim/trusted.hosts

# A set of internal hosts whose mail should be signed
InternalHosts       /etc/opendkim/trusted.hosts" >> /etc/opendkim.conf'

sudo mkdir /etc/opendkim
sudo mkdir /etc/opendkim/keys
sudo chown -R opendkim:opendkim /etc/opendkim
sudo chmod go-rw /etc/opendkim/keys

echo "*@"${Domain}"	default._domainkey."${Domain}"" | sudo tee -a /etc/opendkim/signing.table
echo "*@*."${Domain}"	default._domainkey."${Domain}"" | sudo tee -a /etc/opendkim/signing.table

echo "default._domainkey."${Domain}"	"${Domain}":default:/etc/opendkim/keys/"${Domain}"/default.private" | sudo tee -a /etc/opendkim/key.table

echo "127.0.0.1" | sudo tee -a /etc/opendkim/trusted.hosts
echo "localhost" | sudo tee -a /etc/opendkim/trusted.hosts
echo "" | sudo tee -a /etc/opendkim/trusted.hosts
echo "*."${Domain}"" | sudo tee -a /etc/opendkim/trusted.hosts

sudo mkdir /etc/opendkim/keys/${Domain}
sudo opendkim-genkey -b 2048 -d ${Domain} -D /etc/opendkim/keys/${Domain} -s default -v

sudo chown opendkim:opendkim /etc/opendkim/keys/${Domain}/default.private
sudo chmod 600 /etc/opendkim/keys/${Domain}/default.private

DKIM=$(sudo cat /etc/opendkim/keys/${Domain}/default.txt)
Public_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

DKIM=$(echo $DKIM | cut -d "(" -f2 | cut -d ")" -f1)
DKIM=$(echo "$DKIM" | tr -d '"')
DKIM=$(echo "$DKIM" | tr -d ' ')

#----------------- DMARC RECORD CONFIG
DMARC=v\=DMARC1\;p\=none\;pct\=100\;rua\=mailto:${EmailID}\@${Domain}

#----------------- DOMAIN DNS CONFIG

/home/linuxbrew/.linuxbrew/bin/vultr-cli dns domain create --domain $Domain --ip $Public_IP
/home/linuxbrew/.linuxbrew/bin/vultr-cli dns record create -t TXT -d $DMARC -m $Domain -n'_dmarc' -m $Domain
/home/linuxbrew/.linuxbrew/bin/vultr-cli dns record create -t TXT -d "v=spf1 mx ~all" -n '' -m $Domain
/home/linuxbrew/.linuxbrew/bin/vultr-cli dns record create -t TXT -d $DKIM -n 'default._domainkey' -m $Domain

sudo mkdir /var/spool/postfix/opendkim
sudo chown opendkim:postfix /var/spool/postfix/opendkim
sudo sed -i -r 's/\local:.*/local:\/var\/spool\/postfix\/opendkim\/opendkim.sock/' /etc/opendkim.conf
sudo sed -i -r 's/\local:.*/\"local:\/var\/spool\/postfix\/opendkim\/opendkim.sock\"/' /etc/default/opendkim
sudo bash -c 'echo "
# Milter configuration
milter_default_action = accept
milter_protocol = 6
smtpd_milters = local:opendkim/opendkim.sock
non_smtpd_milters = \$smtpd_milters" >> /etc/postfix/main.cf'

sudo systemctl restart opendkim postfix

#-------------- INSTALL CERTBOT & OPEN PORTS
sudo apt install snapd 
sudo snap install core 
sudo snap refresh core 
sudo snap install --classic certbot 
sudo ln -s /snap/bin/certbot /usr/bin/certbot 
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 80
Email=$EmailID\@$Domain

#-------------- GET DOMAIN CERTIFICATES
sleep 3m
sudo certbot certonly --standalone --non-interactive --agree-tos -m $Email -d $Domain -v

#-------------- CONFIGURE GOPHISH
sudo mkdir /opt/gophish
sudo wget https://github.com/gophish/gophish/releases/download/v0.11.0/gophish-v0.11.0-linux-64bit.zip -O /opt/gophish/gophish.zip
cd /opt/gophish
sudo unzip /opt/gophish/gophish.zip
sudo chmod +x /opt/gophish/gophish
cd /./

sudo mkdir /opt/gophish/ssl_keys
sudo cp "/etc/letsencrypt/live/$Domain/privkey.pem" /opt/gophish/c.key
sudo cp "/etc/letsencrypt/live/$Domain/fullchain.pem" /opt/gophish/c.crt​
sudo mv /opt/gophish/c.crt* /opt/gophish/c.crt
sudo chmod 644 /opt/gophish/c.crt
sudo chmod 644 /opt/gophish/c.key

#-------------- POINT CONFIG TO FULL CERT PATH KEYS & CHANGED ADMIN TO 0.0.0.0
sudo sed -i -r 's/127\.0\.0\.1/0\.0\.0\.0/' /opt/gophish/config.json
sudo sed -i -r 's/false/true/' /opt/gophish/config.json
sudo sed -i -r 's/80/443/' /opt/gophish/config.json
sudo sed -i -r 's/example/\c/' /opt/gophish/config.json

sudo sed -i 's#\"cert_path\": \"\\.crt\"#\"cert_path\": \"/opt/gophish/c.crt\"#' /opt/gophish/config.json
sudo sed -i 's#\"key_path\": \"\\.key\"#\"key_path\": \"/opt/gophish/c.key\"#' /opt/gophish/config.json

sudo mkdir /var/log/gophish
sudo touch /var/log/gophish/gophish.log
sudo touch /var/log/gophish/gophish.error

sudo ufw allow 3333

#-------------- TO RUN GOPHISH
# Enter the below commands manually
# cd /opt/gophish
# sudo ./gophish &

#TESTING POSTFIX EMAIL CONFIG
#sudo bash -c 'echo "Hello - This is an Email Test" >> test_message'
#cat ~/test_message | s-nail -s 'Test email subject line' -r {YOUR_SENDING_ADDRESS} {YOUR_RECIPIENT_ADDRESS}
