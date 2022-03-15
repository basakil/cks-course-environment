
The idea here is to create a new "user" that can communicate with K8s.

For this now:

Create a new KEY at /root/60099.key for user named 60099@internal.users
Create a CSR at /root/60099.csr for the KEY


Explanation

Users in K8s are managed via CRTs and the CN/CommonName field in them. The cluster CA needs to sign these CRTs.

This can be achieved with the following procedure:

Create a KEY (Private Key) file
Create a CSR (CertificateSigningRequest) file for that KEY
Create a CRT (Certificate) by signing the CSR. Done using the CA (Certificate Authority) of the cluster


Tip

openssl genrsa -out XXX 2048

openssl req -new -key XXX -out XXX


Solution

openssl genrsa -out 60099.key 2048

openssl req -new -key 60099.key -out 60099.csr
# set Common Name = 60099@internal.users

===================

CertificateSigningRequests sign manually

Manually sign the CSR with the K8s CA file to generate the CRT at /root/60099.crt .

Create a new context for kubectl named 60099@internal.users which uses this CRT to connect to K8s.



## My:
###     from: https://kubernetes.io/docs/tasks/administer-cluster/certificates/#openssl
openssl x509 -req -in /root/60099.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /root/60099.crt -days 10000
### view via:
openssl x509  -noout -text -in /root/60099.crt

### add to kubeconfig:
kubectl config set-credentials 60099@internal.users --client-key=/root/60099.key --client-certificate=/root/60099.crt --embed-certs=true
kubectl config set-context 60099@internal.users --cluster=kubernetes --user=60099@internal.users

## get and use? optional:
k config get-contexts
k config use-context 60099@internal.users
k get ns # fails because no permissions, but shows the correct username returned



===========================

Signing via API:

## copy the base64 csr
cat 60099.csr | base64 | tr -d "\n"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: 60099@internal.users
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ3FUQ0NBWkVDQVFBd1pERUxNQWtHQTFVRUJoTUNRVlV4RXpBUkJnTlZCQWdNQ2xOdmJXVXRVM1JoZEdVeApJVEFmQmdOVkJBb01HRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERWRNQnNHQTFVRUF3d1VOakF3Ck9UbEFhVzUwWlhKdVlXd3VkWE5sY25Nd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUIKQVFEbDRKZEVvd3psemJ5bzRGTE9ldmJsMkhnWWVicllJdG01QVk3a1VjOS9wUERRTTVFbWxkS3FTTW1rTWZwcQpSUmZhR1UyOUtIUmorYk9ZTVQrN0l1aW1OLzUyeVFROTlNT2RnQnM1N3JuNUJId25jdVY2d3N3SmdzUGJ5SjRrCm1mRWVoYWxmVmppRXNnSytkYVI3NVBiOGJsV01tSnI1Y2tRVG52bitvTFA1cEdXUXN6c2dEU1BTeUplQkNGREEKOWY4dDN1dnVKazh5bzhWOVpGTTQxU2t5Q3J6dThvWS9oUHJrSjFPNDh5cXNIV2RIQldiakhEZ002bXRDQkZhbwora2hBeVFiZG15a2xCdFBBbWpNclMyK3FPeTZ4ZHZYUDdoaXBXK0d0azVHemxiME5jTmxQUk9JZnlmbVp0U1g5CmdRRW0xbnN3MVc0a1JkTkZCK1cwbXVxZEFnTUJBQUdnQURBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQUx5Y2QKU1FlcWVrRUZtVzJReGVHRkwzRXBSMlVjQ1NqdXlqalhnVlVBYlluaEorTjhpNW5Bb2RjT1VJcXNqQVo1c0k5dwpFZHR1WFlUVUNEa1MvdlQ3WjY0MWY2SEpGWU10eGlYYVd6T21HV2lQK0xHVEdPd2NRV3FHQTRMNHdyaXRIUmo5CmU3dWtzNDN2ckx6QnhVU3E2KzNraFRaNlJRVFJpYjhYMHdLWGM5WkFmTTZYQ0dMVU01WEd5REYrQUt0RjRUZWUKNEVmNFhLTlFzWklkKzdidlNNVFBFZk5USUZtalVrSkErZWY2NnRHalY4cFBvUHRTUEtzbXFWM3ZsY01MeExHSwoxVUE4cFNPRmV1MnJJeE9JWjZtR1kwYjBxejZqM0pxVHUyUFJxbkZMWmM0SnZ5Q1lTZjQ1VGI1TkJxVTcwckprCkNxeitpdHVwYmhCZ2hESDZadz09Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF


# kubectl get csr

k certificate approve 60099@internal.users

# kubectl get csr/60099@internal.users -o yaml

kubectl get csr/60099@internal.users -o jsonpath='{.status.certificate}'| base64 -d > 60099.crt
