# 🧪 Lab: Upgrade Kubernetes Cluster from v1.32.2 to v1.33.2 (kubeadm)

## 🎯 Objective

Upgrade a Kubernetes cluster created using **kubeadm** from **version 1.32.2** to **1.33.2** with zero workload impact and following official best practices.

---

## 📌 Prerequisites

* Kubernetes cluster initialized using **kubeadm**
* Control Plane + Worker Nodes
* SSH access to all nodes
* Root or sudo privileges
* Cluster health should be **Healthy**

---

## 🧱 Step 1: Verify Current Cluster Version

```bash
kubectl get nodes
kubectl version --short
```

### 🔍 Explanation

This confirms:

* Current Kubernetes version (1.32.2)
* All nodes are in **Ready** state before upgrade

---

## 🧱 Step 2: Drain Worker Nodes (One by One)

```bash
kubectl drain worker-node-1 --ignore-daemonsets --delete-emptydir-data
```

### 🔍 Explanation

* Safely evicts workloads from the node
* Prevents application downtime
* DaemonSets are ignored because they are node-specific

⚠️ **Never upgrade kubelet while workloads are running**

---

## 🧱 Step 3: Upgrade kubeadm on Control Plane Node

### Update package repository

```bash
sudo apt update
```

### Install kubeadm v1.33.2

```bash
sudo apt install -y kubeadm=1.33.2-*
```

### 🔍 Explanation

* `kubeadm` **must be upgraded first**
* It controls the upgrade process and validates cluster compatibility

---

## 🧱 Step 4: Verify Upgrade Plan

```bash
sudo kubeadm upgrade plan
```

### 🔍 Explanation

* Shows current version
* Lists available upgrade versions
* Confirms if the cluster can safely move to `v1.33.2`

---

## 🧱 Step 5: Upgrade Control Plane Components

```bash
sudo kubeadm upgrade apply v1.33.2
```

### 🔍 Explanation

This step upgrades:

* API Server
* Controller Manager
* Scheduler
* etcd (if managed by kubeadm)

✔️ Static pod manifests under `/etc/kubernetes/manifests` are updated

---

## 🧱 Step 6: Upgrade kubelet and kubectl on Control Plane

```bash
sudo apt install -y kubelet=1.33.2-* kubectl=1.33.2-*
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 🔍 Explanation

* `kubelet` must match control plane version
* Restart loads new binaries
* Control plane node now runs v1.33.2

---

## 🧱 Step 7: Uncordon Control Plane Node

```bash
kubectl uncordon control-plane-node
```

### 🔍 Explanation

* Allows scheduling workloads again
* Control plane is fully upgraded and healthy

---

## 🧱 Step 8: Upgrade Worker Nodes (Repeat for Each Node)

### On worker node:

```bash
sudo apt update
sudo apt install -y kubeadm=1.33.2-*
sudo kubeadm upgrade node
```

### 🔍 Explanation

* Updates node configuration
* Syncs node with upgraded control plane

---

### Upgrade kubelet on worker node

```bash
sudo apt install -y kubelet=1.33.2-*
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

---

### Uncordon worker node

```bash
kubectl uncordon worker-node-1
```

### 🔍 Explanation

* Node rejoins cluster
* Pods can be scheduled again

Repeat **Step 8** for all worker nodes.

---

## 🧱 Step 9: Verify Cluster After Upgrade

```bash
kubectl get nodes
kubectl version --short
```

### ✅ Expected Output

* All nodes in **Ready** state
* Server & Node version → **v1.33.2**

---

## 🧱 Step 10: Validate Core System Pods

```bash
kubectl get pods -n kube-system
```

