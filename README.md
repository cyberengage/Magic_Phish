# Magic_Phish

Magic_Phish is a script to set up a Postfix mailserver, configure domain DNS, and establish a phishing simulation server. Additionally, it handles TLS certificates for both emails and landing pages.

# Features
 - Set up and configure Postfix for mailing services.
 - SPF and DKIM record configuration for domain validation.
 - DMARC record configuration for email security.
 - Automated DNS record configuration using Vultr's API.
 - Certbot integration for automated TLS certificate management.
 - Gophish installation and configuration for phishing simulation campaigns.

# Prerequisites
Ensure you have the following before you proceed:

 - A domain you own, with the nameservers set to Vultr nameservers (ns1.vultr.com & ns2.vultr.com).
 - A Vultr Ubuntu 22.04 x64 VPS instance.
 - Non root linux user with sudo privileges.
 - Vultr API key (this must be enabled on your Vultr account). 

# Usage
#### Clone this repository:
git clone https://github.com/cyberengage/Magic_Phish.git

#### Navigate to the project directory:
cd magic_phish

* Edit the script vavriables at the top of each script to include your Linux username, domain, Vultr API key, and email ID.

#### Run the Script1.sh WITHOUT sudo privilieges user:
bash Sript1.sh

#### Run the Script2.sh WITH sudo privileges:
bash Sript1.sh

#### After execution, run Gophish with the following commands:
cd /opt/gophish
sudo ./gophish &

# Acknowledgments
 - GoPhish: This project utilizes GoPhish, an open-source phishing toolkit. 
   - URL: https://github.com/gophish/gophish

 - Postfix: An essential part of this setup, Postfix is a free and open-source mail transfer agent that routes and delivers electronic mail.  
   - URL: http://www.postfix.org/

 - Vultr-cli: This script leverages the command-line capabilities of Vultr-cli to interact with the Vultr API, enabling automated DNS configurations.
   - URL: https://github.com/vultr/vultr-cli

 - s-nail: Used for email testing in the script, s-nail provides a simple and user-friendly environment for sending and receiving mail. 
   - URL: https://www.sdaoden.eu/code.html#s-nail

 - Certbot: To automate the process of obtaining and renewing SSL certificates, this project utilizes Certbot, a free, open-source software tool.
   - URL: https://certbot.eff.org/

We extend our gratitude to the developers and contributors of these tools and libraries for their valuable contributions to the open-source community.

# Disclaimer
Magic_Phish is intended for educational and research purposes only. 
Do not use this script in enterprise phishing simulations, malicious phishing activities, or any unauthorized activities. 

#### Important: This setup has not been audited for complete security. It's not recommended to deploy this in an enterprise environment as there are numerous security considerations that aren't addressed by this script. Use at your own risk.
