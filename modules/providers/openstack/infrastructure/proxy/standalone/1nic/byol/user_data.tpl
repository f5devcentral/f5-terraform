#!/bin/bash

# Script must be non-blocking or run in the background.

mkdir -p /config/cloud

cat << 'EOF' > /config/cloud/startup-script.sh
#!/bin/bash 

# 1 NIC STARTUP SCRIPT

LOG_FILE=/var/log/startup-script.log
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
     # nohup $0 0<&- &>/dev/null &
else
    #if file exists, exit as only want to run once
    exit
fi

### ONBOARD INPUT PARAMS 

hostname=$(egrep -m 1 'host-name' /var/lib/dhclient/dhclient.leases | sed 's/.*\"\(.*\)\";/\1/')

# v13 uses mgmt for ifconfig & defaults to 8443 for GUI for Single Nic Deployments
if ifconfig mgmt; then managementInterface=mgmt; else managementInterface=eth0; fi
managementAddress=$(egrep -m 1 -A 1 $managementInterface /var/lib/dhclient/dhclient.leases | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
managementGuiPort=${management_gui_port}

adminUsername='${admin_username}'
adminPassword='${admin_password}'

dnsServer=${dns_server}
ntpServer=${ntp_server}
timezone=${timezone}

license_key=${license_key}

# Add SSH Key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClW+UyY2eWczwnEGcEtwR/ISURqmdQIpgicgVvUvZTilE5KstuyBXznpxYT3m2H/7uh5g5syAmS7rX8wSsrbtRjkFgWmDIRPaj3Dqlqqq9N+3TI3mUhMPPWuFZxhW2rK7T6OrWUw5cnJstb89OCQjH4ptqzxIV135re3nT1cJx9JZKxBeYM/tMqZHjAmCwBlj8ndbaidg/f4P0cXa3BS8etcuFGoMwnzACNtkpf6/juodedHbOW9mjamdIoOEVawHiuZNry4emxgT8x9KzBnKHAwRKhLMY/JSc+5z7n21JfDdUIa78Vv3yM3LIaZmpbBPQ7tpJpt4SmYfbhWIUm+z9 a.applebaum@f5.com" >> /home/root/.ssh/authorized_keys

### DOWNLOAD ONBOARDING LIBS
# Could be pre-packaged or hosted internally

libs_dir="/config/cloud/openstack/node_modules"
mkdir -p $libs_dir
curl -o /config/cloud/f5-cloud-libs.tar.gz --silent --fail --retry 60 -L https://raw.githubusercontent.com/F5Networks/f5-cloud-libs/v3.1.1/dist/f5-cloud-libs.tar.gz
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C $libs_dir

### BEGIN BASIC ONBOARDING 

# WAIT FOR MCPD (DATABASE) TO BE UP TO BEGIN F5 CONFIG

. $libs_dir/f5-cloud-libs/scripts/util.sh
wait_for_bigip

# PASSWORD
# Generate Random Password
#f5-rest-node /config/cloud/aws/node_modules/f5-cloud-libs/scripts/generatePassword --file /config/cloud/aws/.adminPassword"
#adminPassword=$(/bin/sed -e $'s:[!\\'\"%{};/|#\\x20\\\\\\\\]:\\\\\\\\&:g' < /config/cloud/aws/.adminPassword)      
# Use Password Provided as Input Param
tmsh create auth user $${adminUsername} password $${adminPassword} shell bash partition-access replace-all-with { all-partitions { role admin } }
tmsh save /sys config

# License / Provision
f5-rest-node $libs_dir/f5-cloud-libs/scripts/onboard.js \
-o  /var/log/onboard.log \
--no-reboot \
--port $${managementGuiPort} \
--ssl-port $${managementGuiPort} \
--host localhost \
--user $${adminUsername} \
--password $${adminPassword} \
--hostname $${hostname} \
--global-setting hostname:$${hostname} \
--dns $${dnsServer} \
--ntp $${ntpServer} \
--tz $${timezone} \
--module ltm:nominal \
--license $${license_key} \
--ping www.f5.com 30 15 \ 


############ BEGIN CUSTOM CONFIG ############

# SOME HIGH LEVEL CONFIG PARAMS

applicationName=${application}
virtualServiceDns=${vs_dns_name}
virtualServiceAddress=${vs_address}
virtualServiceMask=${vs_mask}
virtualServicePort=${vs_port}

applicationPoolName=${pool_name}
applicationPort=${pool_member_port}


# DOWNLOAD SOME ADDITIONAL FILES
curl --silent --fail --retry 20 -o /config/cloud/f5.http.v1.2.0.tmpl https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/f5.http.v1.2.0.tmpl
curl --silent --fail --retry 20 -o /config/cloud/appsvcs_integration_v2.1_001.tmpl https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/appsvcs_integration_v2.1_001.tmpl

# LOAD IAPPS
tmsh load sys application template /config/cloud/f5.http.v1.2.0.tmpl
tmsh load sys application template /config/cloud/appsvcs_integration_v2.1_001.tmpl

# CREATE SSL PROFILES
tmsh install sys crypto cert site.example.com from-local-file /config/ssl/ssl.crt/default.crt
tmsh install sys crypto key site.example.com from-local-file /config/ssl/ssl.key/default.key

# POOL = DNS 
# SERVICE DISCOVERY
tmsh create ltm node $${applicationName} fqdn { name $${applicationPoolName} }

# SERVICE INSERTION
tmsh create sys application service $${applicationName} { template f5.http.v1.2.0 tables add { pool__hosts { column-names { name } rows { { row { $${virtualServiceDns} } } } } pool__members { column-names { addr port connection_limit } rows {{ row { $${applicationName} $${applicationPort} 0 }}}}} variables add { pool__addr { value $${virtualServiceAddress} } pool__mask { value $${virtualServiceMask} } pool__port { value $${virtualServicePort} } pool__port_secure { value $${virtualServicePort} } net__vlan_mode { value all } ssl__cert { value /Common/site.example.com.crt } ssl__key { value /Common/site.example.com.key } ssl__mode { value client_ssl } ssl_encryption_questions__advanced { value yes } ssl_encryption_questions__help { value hide } monitor__http_version { value http11 } }}


# WARNING: If creating a user via startup script, remember to change the password as soon as you login or dispose after provisioning.
# tmsh delete auth user $${adminUsername}

############ END CUSTOM CONFIG ############

tmsh save /sys config
date
echo "FINISHED STARTUP SCRIPT"


EOF


# Now run in the background to not block startup
chmod 755 /config/cloud/startup-script.sh 
nohup /config/cloud/startup-script.sh &


