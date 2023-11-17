# !/bin/bash

CURRENT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
REPO_DIR="$(cd $(dirname ${CURRENT_DIR}) && cd .. && pwd)"

CERT_DIR=${REPO_DIR}/certs/local

rm -rf ${CERT_DIR}

mkdir -p ${CERT_DIR}

cat > ${CERT_DIR}/profiles.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "test": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "8760h"
      }
    }
  }
}
EOF

# generate root ca and key
cat > ${CERT_DIR}/root-ca.json <<EOF
{
  "CN": "Mochi MQTT Root CA",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShaaXi",
      "L": "Xi'an",
      "O": "ACM",
      "OU": "core"
    }
 ],
 "ca": {
    "expiry": "876000h"
 }
}
EOF

cfssl gencert -initca ${CERT_DIR}/root-ca.json | cfssljson -bare ${CERT_DIR}/root-ca


# sign server cert and key

cat > ${CERT_DIR}/server-csr.json <<EOF
{
  "CN":"127.0.0.1",
  "key":{
    "algo":"rsa",
    "size":2048
  },
  "hosts":[
    "127.0.0.1",
    "localhost"
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
  -profile=test ${CERT_DIR}/server-csr.json | cfssljson -bare ${CERT_DIR}/server
