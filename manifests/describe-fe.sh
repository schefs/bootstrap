#!/bin/bash

#SERVER=$(kubectl config view -o=jsonpath='{.clusters[0].cluster.server}')
SERVER=$(kubectl cluster-info |grep -Eo '(http|https)://[^/"]+'|head -1)

# Describe ingress resources IP addres
INGRESS=$(kubectl get svc -n kube-ingress -o jsonpath='{.items[*].status.loadBalancer.ingress[?(@.hostname)].*}')
echo -e "Ingress controller address is:\n\e[32m$INGRESS"
echo -e "\e[0mDummy Exporter is available in :\n\e[32mhttps://$INGRESS/dummy-exporter"

# Grafana service
GRAFANA=$(kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[?(@.hostname)].*}')
echo -e "\e[0mGrafana UI is available in :\n\e[32mhttp://$GRAFANA:3000"

 # Kibana service
KIBANA_PATH=/api/v1/namespaces/monitoring/services/kibana-logging/proxy/app/kibana
echo -e "\e[0mKibana UI is availabe in:\n\e[32m$SERVER$KIBANA_PATH"

# Dashboard access
DASHBOARD_PATH=/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
echo -e "\e[0mK8s Dashboard UI is availabe in:\n\e[32m$SERVER$DASHBOARD_PATH"

# Consul UI 
 CONSUL_SVC_NAME=$(kubectl get svc -n consul -o custom-columns=NAME:.metadata.name | grep consul-ui)
 CONSUL=$(kubectl get svc -n consul $CONSUL_SVC_NAME -o jsonpath='{.status.loadBalancer.ingress[?(@.hostname)].*}')
 echo -e "\e[0mK8s Consul UI is availabe in:\n\e[32mhttp://$CONSUL"

 # WP
 WP_SVC_NAME=$(kubectl get svc -n default -o custom-columns=NAME:.metadata.name | grep wordpress)
 WP=$(kubectl get svc -n default $WP_SVC_NAME -o jsonpath='{.status.loadBalancer.ingress[?(@.hostname)].*}')
 echo -e "\e[0mK8s WordPress UI is availabe in:\n\e[32mhttp://$WP"
 echo Username: user
 echo Password: $(kubectl get secret --namespace default $WP_SVC_NAME -o jsonpath="{.data.wordpress-password}" | base64 --decode)



