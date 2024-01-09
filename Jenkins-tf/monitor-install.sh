#!/bin/bash

sudo useradd \
 --system \
 --no-create-home \
 --shell /bin/false prometheus
#Download the Prometheus file
wget https://github.com/prometheus/prometheus/releases/download/v2.49.0-rc.1/prometheus-2.49.0-rc.1.linux-amd64.tar.gz
tar -xvf prometheus-2.49.0-rc.1.linux-amd64.tar.gz
sudo mkdir -p /data /etc/prometheus
cd prometheus-2.49.0-rc.1.linux-amd64/
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles console_libraries/ prometheus.yml /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
prometheus --version

#Create a systemd configuration file for prometheus
#Edit the file /etc/systemd/system/prometheus.service
#paste the below configurations in your prometheus.service configuration file and save it
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF

[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
 --config.file=/etc/prometheus/prometheus.yml \
 --storage.tsdb.path=/data \
 --web.console.templates=/etc/prometheus/consoles \
 --web.console.libraries=/etc/prometheus/console_libraries \
 --web.listen-address=0.0.0.0:9090 \
 --web.enable-lifecycle
[Install]
WantedBy=multi-user.target
EOF


#Once you write the systemd configuration file for Prometheus, then enable it and start the Prometheus service.
sudo systemctl enable prometheus.service
sudo systemctl start prometheus.service
systemctl status prometheus.service

#(https://<monitoring-server-publiip>:9090) - Prometheus service



########################################### Install a Node Exporter #################################################
#Now, we have to install a node exporter to visualize the machine or hardware level data such as CPU, RAM, etc on our Grafana dashboard.
#To do that, we have to create a user for it.
sudo useradd \
 --system \
 --no-create-home \
 --shell /bin/false node_exporter
#Download the node exporter package
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
node_exporter --version

#Create the systemd configuration file for node exporter.
#Edit the file
#Copy the below configurations and paste them into the /etc/systemd/system/node_exporter.service file.
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind
[Install]
WantedBy=multi-user.target
EOF

#Enable the node exporter systemd configuration file and start it.
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
systemctl status node_exporter.service




######################################### Add Node Exporter to Prometheus target section ###########################
#Now, we have to add a node exporter to our Prometheus target section. So, we will be able to monitor our server.
#edit the file
#Copy the content in the file
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
EOF
#After saving the file, validate the changes that you have made using promtool.
promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload


#(https://<monitoring-server-publiip>:9090/target) - Prometheus service


##################################### INSTALL GRAFANA (https://<server-publiip>:3000) ##################################################
#Now, install the Grafana tool to visualize all the data that is coming with the help of Prometheus.
sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
#Install the Grafana
sudo apt-get install grafana -y
#Enable and start the Grafana Service
sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server.service
sudo systemctl status grafana-server.service

#(https://<monitoring-server-publiip>:3000) - Grafana service

######################################## Steps to follow in Grafana Dashboard ################################
#username and password will be : admin
#Reset the password
#Click on Data sources
#Select the Prometheus
#Provide the Monitoring Server Public IP with port 9090 to monitor the Monitoring Server.
#Name : promethorus
#connection : (https://<monitoring-server-publiip>:9090)
#Click on Save and test
#Go to the dashboard section of Grafana and click on the Import dashboard.
#Add 1860 for the node exporter dashboard and click on Load.
#Then, select the Prometheus from the drop down menu and click on Import



######################################## Monitor Jenkins Server ###########################################
#Now, we have to monitor our Jenkins Server as well.
#For that, we need to install the Prometheus metric plugin on our Jenkins.
#Go to Manage Jenkins -> Plugin search for Prometheus metrics install it and restart your Jenkins.

#Edit the /etc/prometheus/prometheus.yml file
#Copy the content in the file
sudo vim /etc/prometheus/prometheus.yml <<EOF
- job_name: "jenkins"
  metrics_path: '/prometheus'
    static_configs:
      - targets: ["${aws_instance.jenkins_server.public_ip}:8080"]
EOF

#Once you add the Jenkins job, validate the Prometheus config file whether it is correct or not by running the below command.
promtool check config /etc/prometheus/prometheus.yml
#Now, push the new changes on the Prometheus server
curl -X POST http://localhost:9090/-/reload
#Copy the public IP of your Monitoring Server and paste on your favorite browser with a 9090 port with /target

##(https://<monitoring-server-publiip>:9090/target) - Prometheus service




############################################ Steps to add Jenkins in Grafana #############################
#To add the Jenkins Dashboard on your Grafana server.
#Click on New -> Import.
#Provide the 9964 to Load the dashboard.and click on load
#Select the default Prometheus from the drop-down menu and click on Import.
#You will see your Jenkins Monitoring dashboard



###################################### monitor both Kubernetes Servers #########################
#Now, we have to add a node exporter to our Prometheus target section. 
#So, we will be able to monitor both Kubernetes Servers.
#Add both job names(Master & Worker nodes) with their respective public.
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
  - job_name: "node_exporter_masterk8s"
    static_configs:
      - targets: ["${aws_instance.kubernetes_master_server.public_ip}:9100"]

  - job_name: "node_exporter_workerk8s"
    static_configs:
      - targets: ["${aws_instance.kubernetes_worker_server.public_ip}:9100"]
EOF

#validate the changes that you have made using promtool.
promtool check config /etc/prometheus/prometheus.yml

#If your changes have been validated then, push the changes to the Prometheus server.
curl -X POST http://localhost:9090/-/reload