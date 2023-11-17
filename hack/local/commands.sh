# !/bin/bash
# refer to https://mosquitto.org/documentation/dynamic-security/

/usr/sbin/mosquitto -c /home/cloud-user/mosquitto/mosquitto.conf

mosquitto_ctrl dynsec init ./dynamic-security.json admin

mosquitto_ctrl -h 127.0.0.1 -p 8883 \
    --cafile /home/cloud-user/mosquitto/certs/local/root-ca.pem \
    --cert /home/cloud-user/mosquitto/certs/local/admin/client.pem \
    --key /home/cloud-user/mosquitto/certs/local/admin/client-key.pem \
    dynsec listClients

mosquitto_ctrl -h 127.0.0.1 -p 8883 \
    --cafile /home/cloud-user/mosquitto/certs/local/root-ca.pem \
    --cert /home/cloud-user/mosquitto/certs/local/admin/client.pem \
    --key /home/cloud-user/mosquitto/certs/local/admin/client-key.pem \
   dynsec createClient cluster1

mosquitto_ctrl -h 127.0.0.1 -p 8883 \
    --cafile /home/cloud-user/mosquitto/certs/local/root-ca.pem \
    --cert /home/cloud-user/mosquitto/certs/local/admin/client.pem \
    --key /home/cloud-user/mosquitto/certs/local/admin/client-key.pem \
    dynsec addClientRole cluster1 admin 5

mosquitto_sub -h 127.0.0.1 -p 8883 \
    --cafile /home/cloud-user/mosquitto/certs/local/root-ca.pem \
    --cert /home/cloud-user/mosquitto/certs/local/cluster1/client.pem \
    --key /home/cloud-user/mosquitto/certs/local/cluster1/client-key.pem \
    -t sources/maestro/clusters/+/status -q 1 \
    -d
