# kubernetes-certbot

Uses [certbot][certbot] to obtain an X.509 certificate from [Let's encrypt][letsencrypt] and stores it as secret in
[Kubernetes][kubernetes].

## Usage

Create a configmap for your secret -> domains mapping:

```yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: letsencrypt-ssl-certificates
data:
  ssl-certifcates.properties: |
    some-secret-name=example.com,www.example.com
```

Create a deployment for certbot (fill in your email and consider allocating secure persistant storage for the
letsencrypt-data volume):

```yml
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kubernetes-certbot
  labels:
    app: kubernetes-certbot
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: kubernetes-certbot
    spec:
      containers:
        - name: certbot
          image: choffmeister/kubernetes-certbot:latest
          imagePullPolicy: Always
          env:
            - name: SECRET_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: LETS_ENCRYPT_EMAIL
              # TODO: Provide an email for let's encrypt.
              value: fill-this-in@example.com
          volumeMounts:
            - mountPath: /etc/letsencrypt
              name: letsencrypt-data
            - mountPath: /etc/letsencrypt-certs
              name: letsencrypt-certs-config
      volumes:
        - name: letsencrypt-data
          # TODO: Consider using real, secure storage on your cluster.
          emptyDir: {}
        - name: letsencrypt-certs-config
          configMap:
            name: letsencrypt-ssl-certificates
```

Create a service:

```shell
kubectl expose deployment kubernetes-certbot --port=80
```

Configure your front gateway, and point your DNS at the gateway, if you haven't already. Examples below; these assume
you have [kube-dns][kubedns] running, so that nginx is able to resolve the host `kubernetes-certbot`):

### Example: [straight nginx][nginx]

 To forward all incoming traffic for certbot to the service:

```
# nginx.conf
server {
  listen 80 default_server;
  server_name _;

  location /.well-known/acme-challenge/ {
    proxy_pass http://kubernetes-certbot;
  }
}
```

### Example: [ingress-controller][ingress-controller]

You'll want to use add a route to your host:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: certbot-ingress
  annotations:
    # Needed if your ingress controller forces SSL redirects
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /.well-known/acme-challenge/
            backend:
              serviceName: kubernetes-certbot
              servicePort: 80
    - host: www.example.com
      http:
        paths:
          - path: /.well-known/acme-challenge/
            backend:
              serviceName: kubernetes-certbot
              servicePort: 80
```

## And done

And that should work; the next time the certbot runs, it will create the secret "some-secret-name" for those hosts. The
certbot checks once every day if it needs to renew your certificates, and creates and/or updates the appropriate secrets;
if using the nginx-ingress-controller it should reload the config when the secrets change.

## Manual renew run:

If you don't want to wait the initial 5 minutes, or you want to retry, you can run the cert generation with:

```shell
kubectl exec $(kubectl get pods -l app=kubernetes-certbot --output=jsonpath={.items..metadata.name}) -- ./renew_certs.sh
```

[letsencrypt]: https://letsencrypt.org/
[certbot]: https://github.com/certbot/certbot
[kubernetes]: http://kubernetes.io/
[nginx]: https://nginx.org/
[kubedns]: https://github.com/kubernetes/kubernetes/tree/master/build/kube-dns
[ingress-controller]: https://github.com/kubernetes/contrib/tree/master/ingress/controllers
