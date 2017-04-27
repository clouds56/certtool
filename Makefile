#!/usr/bin/sh
EXPIRE=400
SUBJ=C=US/ST=CA/O=Clouds, Person./OU=Clouds K620c
SERIAL=-CAcreateserial
EXTFILE=-extfile ext.cnf

.PRECIOUS: %.key %.csr %.crt %.pem
.PHONY: self intermediate target clean show show-csr

# make self CN=clouds+ca
# make intermediate CN=zz CA=clouds+ca.self
# make target CN=clouds CA=zz.intermediate

%.key:
	openssl genrsa -aes256 -out $@ 4096 && chmod og-rwx $@
	chmod og-rwx $@

%.csr: %.key
	openssl req -new -sha256 -key $< -subj "/CN=$(subst +, ,${CN})/${SUBJ}/" -out $@
	chmod og-rwx $@

%.self.crt: %.self.key
	openssl req -new -x509 -sha256 -days ${EXPIRE} -extensions v3_ca -subj "/CN=$(subst +, ,${CN})/${SUBJ}/" -key $< -out $@
	chmod o-rwx $@

%.intermediate.crt: %.intermediate.csr
	openssl x509 -req -days ${EXPIRE} ${EXTFILE} -extensions v3_ca -CA ${CA}.crt -CAkey ${CA}.key ${SERIAL} -in $*.intermediate.csr -out $@
	chmod o-rwx $@

%.target.crt: %.target.csr
	openssl x509 -req -days ${EXPIRE} ${EXTFILE} -extensions v3_req -CA ${CA}.crt -CAkey ${CA}.key ${SERIAL} -in $*.target.csr -out $@
	chmod o-rwx $@

self: ${CN}.self.crt
	cat $< > $(patsubst %.crt,%.pem,$<)

intermediate: ${CN}.intermediate.crt
	cat $< ${CA}.pem > $(patsubst %.crt,%.pem,$<)

target: ${CN}.target.crt
	cat $< ${CA}.pem > $(patsubst %.crt,%.pem,$<)

clean:
	rm -rf ${CN}.*

show:
	openssl x509 -noout -text -in ${CN}.crt

show-csr:
	openssl req -noout -text -in ${CN}.csr
