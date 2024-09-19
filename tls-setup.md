To deploy an NGINX application on your AWS-based Kubernetes cluster with a TLS certificate using OpenSSL and expose it via a NodePort service, follow these steps:

### **Prerequisites:**
- A running Kubernetes cluster on AWS.
- `kubectl` configured to access your cluster.
- `openssl` installed on your system.

### **Step 1: Create an RSA Key and a Self-Signed Certificate**
First, generate the TLS certificate and private key using OpenSSL.

1. **Generate a private key**:
   ```bash
   openssl genrsa -out tls.key 2048
   ```

2. **Generate a self-signed certificate** (valid for 1 year):
   ```bash
   openssl req -new -x509 -key tls.key -out tls.crt -days 365 -subj "/CN=nginx/O=nginx"
   ```

This will create a private key (`tls.key`) and a certificate (`tls.crt`).

### **Step 2: Create a Kubernetes Secret for the TLS Certificate**
Store the TLS certificate and key in a Kubernetes secret.

1. **Create the secret**:
   ```bash
   kubectl create secret tls nginx-tls-secret --cert=tls.crt --key=tls.key
   ```

This creates a secret named `nginx-tls-secret` which will be used by the NGINX deployment.

### **Step 3: Create the NGINX Deployment**
Now, create a Kubernetes deployment for the NGINX application.

1. **Create a file named `nginx-deployment.yaml`** with the following content:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deployment
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nginx
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
         - name: nginx
           image: nginx:latest
           ports:
           - containerPort: 443
           volumeMounts:
           - name: tls-certs
             mountPath: /etc/nginx/tls
             readOnly: true
         volumes:
         - name: tls-certs
           secret:
             secretName: nginx-tls-secret
   ```

This deployment mounts the TLS certificate from the secret as a volume inside the NGINX container, placing it at `/etc/nginx/tls`.

2. **Deploy the NGINX application**:
   ```bash
   kubectl apply -f nginx-deployment.yaml
   ```

### **Step 4: Create an NGINX Configuration ConfigMap**
You need to configure NGINX to use the TLS certificate.

1. **Create a file named `nginx-config.yaml`** with the following content:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: nginx-config
   data:
     default.conf: |
       server {
           listen 443 ssl;
           server_name _;

           ssl_certificate /etc/nginx/tls/tls.crt;
           ssl_certificate_key /etc/nginx/tls/tls.key;

           location / {
               root /usr/share/nginx/html;
               index index.html index.htm;
           }
       }
   ```

2. **Create the ConfigMap**:
   ```bash
   kubectl apply -f nginx-config.yaml
   ```

### **Step 5: Expose NGINX via NodePort**
To access the NGINX service externally, expose it using a NodePort.

1. **Create a file named `nginx-service.yaml`** with the following content:

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: nginx-service
   spec:
     type: NodePort
     selector:
       app: nginx
     ports:
     - port: 443
       targetPort: 443
       protocol: TCP
       nodePort: 32000  # You can change this port as needed (between 30000-32767)
   ```

2. **Deploy the NodePort service**:
   ```bash
   kubectl apply -f nginx-service.yaml
   ```

### **Step 6: Update the NGINX Deployment to Use the ConfigMap**
Now, mount the ConfigMap into the NGINX pod to use the custom TLS configuration.

1. **Update the `nginx-deployment.yaml` file** to include the ConfigMap as a volume:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deployment
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nginx
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
         - name: nginx
           image: nginx:latest
           ports:
           - containerPort: 443
           volumeMounts:
           - name: tls-certs
             mountPath: /etc/nginx/tls
             readOnly: true
           - name: nginx-config
             mountPath: /etc/nginx/conf.d
         volumes:
         - name: tls-certs
           secret:
             secretName: nginx-tls-secret
         - name: nginx-config
           configMap:
             name: nginx-config
   ```

2. **Apply the updated deployment**:
   ```bash
   kubectl apply -f nginx-deployment.yaml
   ```

### **Step 7: Access the NGINX Application**
1. **Get the external IP of one of the Kubernetes nodes**:
   ```bash
   kubectl get nodes -o wide
   ```

2. **Access the NGINX service**:
   In your browser or via `curl`, access the NGINX service by using the node's external IP and the `NodePort` (e.g., `https://<NodeIP>:32000`).

   Example:
   ```bash
   curl -k https://<NodeIP>:32000
   ```

   **Note**: The `-k` option is to bypass the certificate verification since this is a self-signed certificate.

### **Step 8: Verify the TLS Connection**
You can verify that the connection is using TLS by checking the details with `curl`:

```bash
curl -v -k https://<NodeIP>:32000
```


### **Add the Self-Signed Certificate to Your Browser (Trusted Access)**
To avoid the browser warnings, you can manually add the self-signed certificate as a trusted certificate on the machine you're using to access NGINX.

#### Steps to Add the Certificate to the Browser:

1. **Export the Self-Signed Certificate**:
   Ensure you have the `tls.crt` file that was generated by OpenSSL.

2. **Import the Certificate into the Browser**:
   Here’s how you can add the certificate as trusted in common browsers:

   - **Google Chrome** (on Windows/Mac):
     1. Open Chrome and go to **Settings** → **Privacy and Security** → **Security** → **Manage certificates**.
     2. In the **Authorities** tab, click **Import**.
     3. Select your self-signed certificate (`tls.crt`) and import it.
     4. Restart your browser.

   - **Firefox**:
     1. Open **Firefox** and go to **Settings** → **Privacy & Security**.
     2. Scroll down to **Certificates** and click **View Certificates**.
     3. Under the **Authorities** tab, click **Import**.
     4. Select your `tls.crt` file and check the option **Trust this CA to identify websites**.
     5. Click **OK** and restart Firefox.

   - **Safari** (on macOS):
     1. Open **Keychain Access** (search for it using Spotlight).
     2. Drag and drop your `tls.crt` file into the **System** or **Login** keychain.
     3. Double-click the certificate, expand **Trust**, and set **When using this certificate** to **Always Trust**.
     4. Close the window and enter your password to confirm.

   - **Microsoft Edge**:
     Edge uses the same certificate store as Windows, so the steps are similar to Chrome. You can manage certificates via **Internet Options** in the Control Panel and add the self-signed certificate under **Trusted Root Certification Authorities**.

Once you’ve added the self-signed certificate, your browser will no longer show warnings when accessing the NGINX service over HTTPS.

