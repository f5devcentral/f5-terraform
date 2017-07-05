#!/bin/bash

# Script must be non-blocking or run in the background.

mkdir -p /config/cloud

cat << 'EOF' > /config/cloud/startup-script.sh


#!/bin/bash

## 1NIC BIG-IP ONBOARD SCRIPT

## IF THIS SCRIPT IS LAUNCHED EARLY IN BOOT (ex. when from cloud-init), YOU NEED TO RUN IT IN THE BACKGROUND TO NOT BLOCK OTHER STARTUP FUNCTIONS
# ex. location of interpolated cloud-init script
#/opt/cloud/instances/i-079ac8a174eb1727a/scripts/part-001

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

region=${region}

adminUsername='${admin_username}'
adminPassword='${admin_password}'

hostname=`curl --silent --fail --retry 20 http://169.254.169.254/latest/meta-data/hostname`
dnsServer=${dns_server}
ntpServer=${ntp_server}
timezone=${timezone}

# Management Interface uses DHCP 
# v13 uses mgmt for ifconfig & defaults to 8443 for GUI for Single Nic Deployments
if ifconfig mgmt; then managementInterface=mgmt; else managementInterface=eth0; fi
managementAddress=$(egrep -m 1 -A 1 $managementInterface /var/lib/dhclient/dhclient.leases | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
managementGuiPort=${management_gui_port}

licenseKey1=${license_key}


### DOWNLOAD ONBOARDING LIBS
# Could be pre-packaged or hosted internally

libs_dir="/config/cloud/aws/node_modules"
mkdir -p $libs_dir
curl -o /config/cloud/f5-cloud-libs.tar.gz --silent --fail --retry 60 -L https://raw.githubusercontent.com/F5Networks/f5-cloud-libs/v3.1.1/dist/f5-cloud-libs.tar.gz
curl -o /config/cloud/f5-cloud-libs-aws.tar.gz --silent --fail --retry 60 -L https://raw.githubusercontent.com/F5Networks/f5-cloud-libs-aws/v1.3.0/dist/f5-cloud-libs-aws.tar.gz
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C $libs_dir
tar xvfz /config/cloud/f5-cloud-libs-aws.tar.gz -C $libs_dir/f5-cloud-libs/node_modules


### BEGIN BASIC ONBOARDING 

# WAIT FOR MCPD (DATABASE) TO BE UP TO BEGIN F5 CONFIG

. $libs_dir/f5-cloud-libs/scripts/util.sh
wait_for_bigip

# PASSWORD
# Generate Random Password
#f5-rest-node $libs_dir/f5-cloud-libs/scripts/generatePassword --file /config/cloud/aws/.adminPassword"
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
--license $${licenseKey1} \
--module ltm:nominal \
--module asm:nominal \
--module avr:nominal \
--ping www.f5.com 30 15 \ 




############ BEGIN CUSTOM CONFIG ############

# SOME HIGH LEVEL CONFIG PARAMS

region=${region}

applicationName=${application}
virtualServiceDns=${vs_dns_name}
virtualServiceAddress=${vs_address}
virtualServiceMask=${vs_mask}
virtualServicePort=${vs_port}

applicationPort=${pool_member_port}
applicationPoolName=${pool_name}
applicationPoolTagKey=${pool_tag_key}
applicationPoolTagValue=${pool_tag_value}

policyLevel="high"
loggingProfileName="asm_log_to_splunk"
analyticsAddress="analytics.demo.f5example.com"
analyticsKey=123456

# DOWNLOAD SOME FILES
curl --silent --fail --retry 20 -o /config/cloud/f5.http.v1.2.0.tmpl https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/f5.http.v1.2.0.tmpl
curl --silent --fail --retry 20 -o /config/cloud/appsvcs_integration_v2.1_001.tmpl https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/appsvcs_integration_v2.1_001.tmpl
curl --silent --fail --retry 20 -o /config/cloud/f5.service_discovery.tmpl https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/f5.service_discovery.tmpl
curl --silent --fail --retry 20 -o /config/cloud/f5.analytics.tmpl https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/f5.analytics.tmpl
curl --silent --fail --retry 20 -o /config/cloud/asm-policy-linux.tar.gz https://raw.githubusercontent.com/f5devcentral/f5-cloud-init-examples/master/files/iApp/policies/asm-policy-linux.tar.gz

# Load iApps
tmsh load sys application template /config/cloud/f5.http.v1.2.0.tmpl
tmsh load sys application template /config/cloud/appsvcs_integration_v2.1_001.tmpl
tmsh load sys application template /config/cloud/f5.service_discovery.tmpl
tmsh load sys application template /config/cloud/f5.analytics.tmpl


echo "ssh-rsa XXXXB3NzaC1yc2EAAAADAQABAAABAQClW+UyY2eWczwnEGcEtwR/ISURqmdQIpgicgVvUvZTilE5KstuyBXznpxYT3m2H/7uh5g5syAmS7rX8wSsrbtRjkFgWmDIRPaj3Dqlqqq9N+3TI3mUhMPPWuFZxhW2rK7T6OrWUw5cnJstb89OCQjH4ptqzxIV135re3nT1cJx9JZKxBeYM/tMqZHjAmCwBlj8ndbaidg/f4P0cXa3BS8etcuFGoMwnzACNtkpf6/juodedHbOW9mjamdIoOEVawHiuZNry4emxgT8x9KzBnKHAwRKhLMY/JSc+5z7n21JfDdUIa78Vv3yM3LIaZmpbBPQ7tpJpt4SmYfbhWIUm+z9 my-ssh-key" >> /home/admin/.ssh/authorized_keys

echo "H4sIAAWfZFgAA2VUy66jOBDd8xWzj1oXCHktemEb4zi5hphn8C44uYSEQCAJr69vcrs1Gk1bKsk6VS4fnTqqHz/GAzGh9j8Iuz61KAI+foM/FEapefMRAiVJQUshSMfwgQ3Ta3W+ZmTVqhDwwAImJIw/WsRjM+Sc4HYTBgP+VBi4EqAFGEGGQhV32AQOTO0QAulDzc7jvasmJOiICaLfOPNNPX8dSdgnUXhVDpGlCk+7xD44Wa3a2RcwMBP3Y+jsYh9GrGc+UJl5/RdjOO7QADbvhgoE49M89P9Dj4709tzHnAHjmx3s2DrQw/Nx7T6Ej2MG428cdHynbLPZzY5CI460dqT6ivXVc9QF0sv/dcAWAA4CfAneeZRuxzsGirbtpuZQmOmOGwMAVkF9oePz8JWFSHjoNXtZvZPMz9VCpXRq+NkHxlRcJ2ihz6tnVithtcy1QQ8l9gQnCYeVIci5jp1Fef88HzIOjTzIH7Centplx17hCXrGKMer3/hbYEll4fvFUa6m6QbexK3HmlXePr/uxqwGuayvnmp07lTjh6ix3LpfA6g10zy1btsosJ+IewphGySDlSqRYS2adbmzl6HWxAvsZCeHuVfrqOEj6ftHqEZ9fjkewnTVh6b4mF2jycFYKiZLCNtLH907GOX20+Men9Nh2K/Dk7fq6qecHwtYH2SXd0zbmfHDEXta7RbbGTfCJFUMVCI7v+reKzDjxKHVjEzmnJqAA1gaxGWUOH/MdsQtRwyAFvN4E1NBQZwYCk8xHGdkglQABh7fhWY7zqelVmmC6m2WtRdgOoAzTNMaptiCXI4f/G6ivLvwlEOYlu8kBjGdopSZzAwIihDxACETTKHJeWllYidJ+Ao0m1Fs57Jw74q45ZfR7zklopEZ9AO1TUM9zKj1LhC5/MtQwR9DYXCQ90hJY7ecHzhdvQ5gr2YTZNfy+ESH6UeqbsXXPQ8qfbMexaGp7xJnGbHKzheZedf8y+2hA4UVkIphwEiW0nvKo6kaD+m392QjyrwR9qyoBgHa1khONU7SQGMT8vVFxLaMnn1RLJXZbVJuZ/tbi58fc7mEi3IW4Xwo4NdwMQ1SF63RnOhBup/TcDvJxXx/mu1eUBIHT3T7CRRhnly3XxW+GImCGp1B/7gvtMnJyBrZZM626UCQ2Ooox2y62IAqmc6n6ofc9bGqE/2mJH3IwqaeXgdu7apr2PdzP/KyjW82ao/OqKmcYr4WRSteDPiHrWps9q800FfZkR1R5SrnS1XIrDYs7DoUOIsO/PypfG87bJt/b8BfbFEEXB4FAAA=" | base64 -d | gunzip >> /config/ssl/ssl.crt/website.crt

# WARNING: For illustrative purposes only. As metadata in AWS is inherently insecure and you need to avoid passing long term private keying material. In production, you would instead download private key in secure fashion (ex. from S3 Bucket that instances had permissions to, server using one-time-only password, etc.) or even pre-install the cert into a custom image.

echo "H4sIALafZFgAA22Vt66kWABEc75icjTCu/DiTWMutiEDuoF+mMa7r9+Z3XQrLZV0VCqpfv/+I1HRDOeXH4Bfnm/EIFR+WUr61/iN2IahfA9DBMCSAFQAYZ2UfA9y7UH6BkAdjDAjleauPrGUBdLGbOrlFmwzcbhhUHSIfDBFMbIWlTiSndbPHE98R9xkXCpBBrUCihOdac2cutx3fDT5B4p0F3WLOFPvgz/tDYnfYkC3l71dZmgBteTCcHiVAlWbYp/1l0Ko3/5RjTQzg66c2wCnT58iYJ7sqj9fOkBEYqe6Wu2tJHJWCQaabUplJOClRKvcrn89h4+JPeUU9/N2bb9VX4Ty0q5rifHk6n5eSB7XwhXLGca0CZrTvGwXmv0sQ2k8xaRz1gAGkDXu+6nH70A457VkX4M45+XZnTbhyUi6uNnTmDzOYiAdFzUtfSWna8lgi+S0cI2J0VAWGjKAQATfP2XLbolS0Kk4ahdx8kIwtm8WRdYeRifvDOPEUdSozOctiud0b3tiSykD1+bbxzyqkmemnFCsuVPgLFcve2pAzmIa/6DJIFNjh3XA5SXfHod9ihHBUKVQtHRwyhfzDgfByeyLfW4yq56k8tPRUaXtyGdopU1Yg+1mGfMgiJ89ygNBTGNUCUlD9I9vb4K7aU2nCQziXO9C+zJMxNxx5HPxpCB/R9P2DL8ru5CDNcTC7rIL+WluMlZw2aPYCny6b8LUa1JwpF7XbT7xXqgn4Gy/agly79u3Zw28Q1HAD/SCj3c7TVLsQ7tpC07DWu0R94NZJ6nrDGXkCi+/fV3VshJrRpcXstr2RzIVqU4VwNupeXrsMYPl8jivnDI6lI8lC3BMvm0nmAl4LEBE2y1HDU+Lb3e0EZLm/AGNzKccsVM0cZnurg2pRwPre60QS7657G6vhu8YQ2F9s+FjTz+YAJmp6m0W1RHLkDI9EmVrztfPPootU53PF3jlmw/dYRNFzd4wFLwjmuwOudNBsYM0w/8lphtUQuzRXg93u8giEuApDSR9NHryYqon2fIlG+ZDiJ/C7k6vOqE0zskhiapMTQJlXI3yuSMPHhwPQ64PmGD9ir4CCS58YFcEUGOjNCnrHNUFq3dxmjnUa2AumND5oMTFwZ/uuf4gndNKUqp+iGt9dUaQhawkh4V6P2lub7eZ+kodEOf/kEkGNdPyABHLBjghMZDkfSSnnCO40h9bBtMFFmyuNzV/mmnLnpanB0u4DD/jY5RoCs+TcCAov6SqYcwr06/bn1BElNdmm55kOdiH4/V9E72PjH7ReBOBLnJZfV/4u3rCCNcIZqVQyk3oubeWM29d8D7rGAF/Onkz3d7KwjFWU/YY32mk/92FiOluZxG7u7zMB40nY3FXx7uopqKrfHzFdA0+7ALhRRz9E9ibc56IbBYlo/+OQvl42wubNU4ZUIHpYUlaKHvSH5WWn++yHhaefRY5raM7Iv38uDsrDsznZFwhObtt+yRd8mb7anofwrXJ3MruvGsBLTGs+kowEAq8zn8d3wpyqkWs99Hp0BJrnWJQLOgwiuLdlBvta3wM8Ar4pPHFbnZcdLnreDXPBC1ylN6Y0zvnT4IhNLb5RZEGLenyRvC8CTWuPOl7MO/HyTWmTkHId6f8Uwpbyvmw65wv02ONQrgJ14uji9z+uYfaFZOx9IA6jlcvoZF6FrdGz3Fs2YIJAZOBLkx27q+zuz37OyH/XoriyP9/Nf8A5vBZx4sGAAA=" | base64 -d | gunzip >> /config/ssl/ssl.key/website.key

tmsh install sys crypto cert site.example.com from-local-file /config/ssl/ssl.crt/website.crt
tmsh install sys crypto key site.example.com from-local-file /config/ssl/ssl.key/website.key


# Advanced Virtual Service

tmsh create security log profile $${loggingProfileName} application add { splunk-logging { filter replace-all-with { request-type { values add { illegal } } search-all } local-storage disabled logic-operation and remote-storage splunk servers add { 255.255.255.254:1001 } } }

tar xvzf /config/cloud/asm-policy-linux.tar.gz -C /config/cloud/
# BEGIN CUSTOMIZE:  Policy Name/Policy URL, etc.
# tmsh modify asm policy names below (ex. /Common/linux-$${POLICY_LEVEL}) to match policy name in the xml file
tmsh load asm policy file /config/cloud/asm-policy-linux-$${policyLevel}.xml
tmsh modify asm policy /Common/linux-$${policyLevel} active
tmsh create ltm policy app-ltm-policy strategy first-match legacy
tmsh modify ltm policy app-ltm-policy controls add { asm }
tmsh modify ltm policy app-ltm-policy rules add { associate-asm-policy { actions replace-all-with { 0 { asm request enable policy /Common/linux-$${policyLevel} } } } }

# POOL = ASG
# SERVICE DISCOVERY

# POOL = ASG
tmsh create ltm pool $${applicationPoolName} monitor http

tmsh create sys application service $${applicationName}_sd { template f5.service_discovery variables add { basic__advanced { value no } basic__display_help { value hide } cloud__aws_region { value $${region} } cloud__aws_use_role { value no } cloud__cloud_provider { value aws } pool__interval { value 60 } pool__lb_method_choice { value least-connections-member } pool__member_conn_limit { value 0 } pool__member_port { value $${applicationPort} } pool__pool_to_use { value /Common/$${applicationPoolName} } pool__public_private { value private } pool__tag_key { value $${applicationPoolTagKey} } pool__tag_value { value $${applicationPoolTagValue} } }}


# SERVICE INSERTION: CREATE VIRTUAL

# ASM VIP w/ Logging to Splunk
tmsh create sys application service $${applicationName} { template f5.http.v1.2.0 tables add { pool__hosts { column-names { name } rows { { row { $${virtualServiceDns} } } } } pool__members { } server_pools__servers { } } variables add { asm__use_asm { value app-ltm-policy } asm__language { value utf-8 }  pool__addr { value $${virtualServiceAddress} } pool__mask { value $${virtualServiceMask} } pool__port { value $${virtualServicePort} } pool__port_secure { value $${virtualServicePort} } pool__pool_to_use { value /Common/$${applicationPoolName} } net__vlan_mode { value all } ssl__cert { value /Common/site.example.com.crt } ssl__key { value /Common/site.example.com.key } ssl__mode { value client_ssl } ssl_encryption_questions__advanced { value yes } ssl_encryption_questions__help { value hide } monitor__http_version { value http11 } asm__security_logging { value asm_log_to_splunk }  }}

tmsh save /sys config

# LOAD ANALYTICS IAPP
tmsh create sys application service Splunk template f5.analytics tables replace-all-with { applicationmapping__mappings { column-names { priority type datasource regex mappingaction appendprefix directmapping } rows { { row { \"\" "App Name" "Virtual Name" '(.*)_vs' Map \"\" \"\" } } { row { \"\" "App Name" "Wideip Name" '(.*)' Map \"\" \"\" } } } } logging__risklogindata { } } variables replace-all-with { alerts__useexistingsplunk { value Yes } applicationmapping__mode { value Define } basic__alerts { value Yes } basic__devicegroupoverride { value \"\" } basic__facility { value NYC } basic__format { value Splunk } basic__ihealth { value No } basic__logging { value Yes } basic__rbac { value No } basic__silverline { value No } basic__stats { value Yes } basic__syslog { value Yes } basic__tenantdefault { value $${virtualServiceDns} } logging__sendadm { value No } logging__sendriskdata { value No } logging__sendrisklogins { value No } logging__useexistingsplunk { value Yes } statistics__splunkapikey { value $${analyticsKey} } statistics__splunkdestinationip { value $${analyticsAddress} } statistics__splunkdestinationport { value 8088 } statistics__splunkdestinationprotocol { value HTTPS } syslog__useexistingsplunk { value Yes } applicationmapping__exportmapping { value \"\"} } }


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


