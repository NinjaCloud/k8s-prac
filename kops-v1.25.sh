#!/bin/bash


echo $'Let\'s get started with Kubernetes cluster creation using KOPS!'
echo "Enter your name:"
read username
lower_username=$(echo -e $username | sed 's/ //g' | tr '[:upper:]' '[:lower:]')
date_now=$(date "+%F-%H-%m")
clname=$(echo $lower_username-$date_now.k8s.local)
echo "Your Kubernetes cluster name will be $clname"
az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)



sudo sed -i "/$nrconf{restart}/d" /etc/needrestart/needrestart.conf
cat /etc/needrestart/needrestart.conf | grep -i $nrconf{restart}
echo "\$nrconf{restart} = 'a';" | sudo tee -a /etc/needrestart/needrestart.conf
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a



sudo apt update -y
sudo apt install nano curl python3-pip -y
sudo pip3 install awscli



curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.25.2/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl



curl -LO https://github.com/kubernetes/kops/releases/download/v1.25.2/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops



Write-Output "y" | ssh-keygen -N "" -f $HOME/.ssh/id_rsa


aws s3 mb s3://$clname --region $region


export KOPS_STATE_STORE=s3://$clname


kops create cluster --node-count=2 --master-size="t2.medium" --node-size="t2.medium" --master-volume-size=20 --node-volume-size=20 --zones $az --name $clname --ssh-public-key ~/.ssh/id_rsa.pub --yes



kops update cluster $clname --yes
echo "export KOPS_STATE_STORE=s3://$clname" >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc



kops export kubecfg --admin


for (( x=0 ; x < 30 ; x++ )); do {
  echo "Validating Cluster"
  ! kops validate cluster > status.txt 2>/dev/null
  if ( grep "k8s.local is ready" status.txt > status1.txt);
  then
         echo "Your Cluster is now ready!"
         break
  else
         sleep 20
         echo "x:" $x
  fi
} done



kops delete cluster --name $clname > delete.txt
export sg1=$(cat delete.txt | grep "sg-" | awk '{print $3}' | sed -n '1p')
export sg2=$(cat delete.txt | grep "sg-" | awk '{print $3}' | sed -n '2p')
export sg3=$(cat delete.txt | grep "sg-" | awk '{print $3}' | sed -n '3p')
aws ec2 authorize-security-group-ingress --group-id $sg1 --protocol tcp --port 30000-32767 --cidr 0.0.0.0/0 --region $region
aws ec2 authorize-security-group-ingress --group-id $sg2 --protocol tcp --port 30000-32767 --cidr 0.0.0.0/0 --region $region
aws ec2 authorize-security-group-ingress --group-id $sg3 --protocol tcp --port 30000-32767 --cidr 0.0.0.0/0 --region $region

echo "export KOPS_STATE_STORE=s3://$clname" >> delete-kops.sh
echo "kops delete cluster " $clname " --yes" >> delete-kops.sh
chmod +x delete-kops.sh
chown ubuntu:ubuntu delete-kops.sh

echo "Creating Kubernetes Dashboard"


cat > kubernetes-dashboard.yaml <<EOF

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard

---

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard

---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 32000
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kubernetes-dashboard
type: Opaque

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-csrf
  namespace: kubernetes-dashboard
type: Opaque
data:
  csrf: ""

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-key-holder
  namespace: kubernetes-dashboard
type: Opaque

---

kind: ConfigMap
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-settings
  namespace: kubernetes-dashboard

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
rules:
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
    verbs: ["get", "update", "delete"]
    # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["kubernetes-dashboard-settings"]
    verbs: ["get", "update"]
    # Allow Dashboard to get metrics.
  - apiGroups: [""]
    resources: ["services"]
    resourceNames: ["heapster", "dashboard-metrics-scraper"]
    verbs: ["proxy"]
  - apiGroups: [""]
    resources: ["services/proxy"]
    resourceNames: ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
    verbs: ["get"]

---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
rules:
  # Allow Metrics Scraper to get metrics from the Metrics server
  - apiGroups: ["metrics.k8s.io"]
    resources: ["pods", "nodes"]
    verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

---

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
        - name: kubernetes-dashboard
          image: kubernetesui/dashboard:v2.4.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8443
              protocol: TCP
          args:
            - --auto-generate-certificates
            - --namespace=kubernetes-dashboard
            # Uncomment the following line to manually specify Kubernetes API server Host
            # If not specified, Dashboard will attempt to auto discover the API server and connect
            # to it. Uncomment only if the default does not work.
            # - --apiserver-host=http://my-address:port
          volumeMounts:
            - name: kubernetes-dashboard-certs
              mountPath: /certs
              # Create on-disk volume to store exec logs
            - mountPath: /tmp
              name: tmp-volume
          livenessProbe:
            httpGet:
              scheme: HTTPS
              path: /
              port: 8443
            initialDelaySeconds: 30
            timeoutSeconds: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      volumes:
        - name: kubernetes-dashboard-certs
          secret:
            secretName: kubernetes-dashboard-certs
        - name: tmp-volume
          emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule

---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 8000
      targetPort: 8000
  selector:
    k8s-app: dashboard-metrics-scraper

---

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: dashboard-metrics-scraper
  template:
    metadata:
      labels:
        k8s-app: dashboard-metrics-scraper
    spec:
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: dashboard-metrics-scraper
          image: kubernetesui/metrics-scraper:v1.0.7
          ports:
            - containerPort: 8000
              protocol: TCP
          livenessProbe:
            httpGet:
              scheme: HTTP
              path: /
              port: 8000
            initialDelaySeconds: 30
            timeoutSeconds: 30
          volumeMounts:
          - mountPath: /tmp
            name: tmp-volume
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      volumes:
        - name: tmp-volume
          emptyDir: {}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kops-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kops-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kops-admin
  namespace: kube-system
---

apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  namespace: kube-system
  name: kops-admin
  annotations: 
    kubernetes.io/service-account.name: "kops-admin"
EOF
kubectl apply -f kubernetes-dashboard.yaml

echo "Retreiving URL of SVC"
export url1="https://"$(kubectl get nodes -o wide -n kubernetes-dashboard | awk '{print $7}' | sed -n '2p')":32000"
export url2="https://"$(kubectl get nodes -o wide -n kubernetes-dashboard | awk '{print $7}' | sed -n '3p')":32000"
export url3="https://"$(kubectl get nodes -o wide -n kubernetes-dashboard | awk '{print $7}' | sed -n '4p')":32000"
echo "                                                   " > token.txt
echo "********        HERE ARE THE DETAILS REQUIRED        ********" >> token.txt
echo "******** You can use any one of the below given URLs ********" >> token.txt
echo "First URL is: " >> token.txt
echo $url1 >> token.txt
echo "Second URL is: " >> token.txt
echo $url2 >> token.txt
echo "Third URL is: " >> token.txt
echo $url3 >> token.txt


#Creating Token
echo "Creating Token"
echo "Token is:" >> token.txt
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kops-admin | awk '{print $1}') | grep token: | awk '{print $2}' >> token.txt
echo "******************          END          ******************" >> token.txt
echo "                                                   " >> token.txt
cat token.txt