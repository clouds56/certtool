#!/usr/bin/sh
EXPIRE=400
SUBJ=C=US/ST=CA/O=Clouds, Person./OU=Clouds K620c
CA=ca.self
CA_CN=Clouds CA
EXTFILE=ext.cnf
SERIAL=-CAcreateserial

.PRECIOUS: %.key %.csr %.crt %.pem
.PHONY: phony_target

# make ca.self
# make zz.intermediate CA=ca.self
# make clouds.target CA=zz.intermediate

%.key:
	openssl genrsa -aes256 -out $@ 4096 && chmod og-rwx $@

%.csr: %.key
	openssl req -new -sha256 -key $< -subj "/CN=$*/${SUBJ}/" -out $@

%.self.crt: %.self.key
	openssl req -new -x509 -sha256 -days ${EXPIRE} -extensions v3_ca -subj "/CN=${CA_CN}/${SUBJ}/" -key $< -out $@
	chmod o-rwx $@

%.intermediate.crt: %.intermediate.csr
	openssl x509 -req -days ${EXPIRE} -extfile ${EXTFILE} -extensions v3_ca -CA ${CA}.crt -CAkey ${CA}.key ${SERIAL} -in $*.intermediate.csr -out $@
	chmod o-rwx $@

%.target.crt: %.target.csr
	openssl x509 -req -days ${EXPIRE} -extfile ${EXTFILE} -extensions v3_req -CA ${CA}.crt -CAkey ${CA}.key ${SERIAL} -in $*.target.csr -out $@
	chmod o-rwx $@

%.self: phony_target %.self.crt
	cat $@.crt > $@.pem

%.intermediate: phony_target %.intermediate.crt
	cat $@.crt ${CA}.pem > $@.pem

%.target: phony_target %.target.crt
	cat $@.crt ${CA}.pem > $@.pem

%.clean: phony_target
	rm -rf $*.*

%.show: phony_target
	openssl x509 -noout -text -in $*.crt

phony_target:
