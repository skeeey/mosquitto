# !/bin/bash

CURRENT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
REPO_DIR="$(cd $(dirname ${CURRENT_DIR}) && cd .. && pwd)"

CERT_DIR=${REPO_DIR}/certs/domain

namespace="mosquitto"
service="mosquitto"
route="mosquitto"
domain=apps.server-foundation-sno-r8b9r.dev04.red-chesterfield.com

cluster_name="cluster2"

cluster_cert_dir=${CERT_DIR}/$cluster_name

rm -rf $cluster_cert_dir
mkdir $cluster_cert_dir

# sign client cert and key

cat > ${cluster_cert_dir}/client-csr.json <<EOF
{
  "CN":"${cluster_name}",
  "key":{
    "algo":"rsa",
    "size":2048
  },
  "hosts":[
    "127.0.0.1",
    "localhost",
    "${service}",
    "${service}.${namespace}",
    "${service}.${namespace}.svc",
    "${service}.${namespace}.svc.cluster.local",
    "${service}-${route}.${domain}"
  ],
  "names":[
    {
      "C":"CN",
      "ST":"ShaaXi",
      "L":"Xi'an",
      "O":"ACM",
      "OU":"core"
    }
  ]
}
EOF

cfssl gencert -ca=${CERT_DIR}/root-ca.pem -ca-key=${CERT_DIR}/root-ca-key.pem \
  -config=${CERT_DIR}/profiles.json \
  -profile=test ${cluster_cert_dir}/client-csr.json | cfssljson -bare ${cluster_cert_dir}/client
