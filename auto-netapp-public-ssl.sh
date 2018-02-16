#!/bin/bash
# Takes Let's Encrypt SSL certificates and generates a script to paste in to your NetApp CLI to automatically install the certificate.
# Paths assume you user acme.sh, adjust variables at top of file as needed.
VSERVER="NTPCLST02"
CERT_CN="ntpclst02.ttl.one"
CERT_CER="/root/.acme.sh/$CERT_CN/$CERT_CN.cer"
CERT_KEY="/root/.acme.sh/$CERT_CN/$CERT_CN.key"
CERT_INTCA="/root/.acme.sh/$CERT_CN/ca.cer"
CERT_CA_CN=`cat $CERT_CER | openssl x509 -noout -text | grep "Issuer: " | awk -F'CN=' '{print $2}'`
CERT_SERIAL=`cat $CERT_CER | openssl x509 -noout -text | grep "Serial Number:" -A1 | tr -d " \t\n\r\:" | awk -F'SerialNumber' '{print $2}' | tr '[:lower:]' '[:upper:]'`
OUT_FILE="$CERT_CN.txt"

echo "set -privilege admin
set -privilege advanced
y
security certificate show
security ssl show -vserver $VSERVER
security certificate delete -vserver $VSERVER *
y
security certificate install -type server
# Certificate
# cat $CERT_CER" > $OUT_FILE
cat $CERT_CER >> $OUT_FILE

echo "
y
# Private Key
# cat $CERT_KEY">>$OUT_FILE
cat $CERT_KEY>>$OUT_FILE

echo "
y
# Intermediate CA Certificate
# cat $CERT_INTCA">>$OUT_FILE
cat $CERT_INTCA>>$OUT_FILE

echo "
y
# Root CA Certificate
# For Fake LE RootCA:
# openssl x509 -in $CERT_INTCA -noout -text | grep 'CA Issuers - URI:' | awk -F'URI:' '{print \$2}' | xargs -i curl -L {} | openssl x509 -inform der
# For Production LE RootCA:
# openssl x509 -in $CERT_INTCA -noout -text | grep 'CA Issuers - URI:' | awk -F'URI:' '{print \$2}' | xargs -i curl -L {} | openssl pkcs7 -inform der -print_certs" >>$OUT_FILE

openssl x509 -in $CERT_INTCA -noout -text | grep 'CA Issuers - URI:' | awk -F'URI:' '{print $2}' | xargs -i curl -L {} | openssl pkcs7 -inform der -print_certs | grep 'BEGIN CERTIFICATE' -A999 --color=NEVER 1>>$OUT_FILE
openssl x509 -in $CERT_INTCA -noout -text | grep 'CA Issuers - URI:' | awk -F'URI:' '{print $2}' | xargs -i curl -L {} | openssl x509 -inform der | grep 'BEGIN CERTIFICATE' -A999 --color=NEVER 1>>$OUT_FILE


echo "n
security ssl modify -vserver $VSERVER -server-enabled true -ca \"$CERT_CA_CN\" -serial $CERT_SERIAL
security ssl show -vserver NTPCLST02
security certificate show
set -privilege admin
exit

" >>$OUT_FILE
