all: create_ca create_api_keys worker_keys admin_keys

create_ca: ca-key.pem ca.pem
create_api_keys: apiserver-key.pem apiserver.csr apiserver.pem
worker_keys: worker-key.pem worker.csr worker.pem
admin_keys: admin-key.pem admin.csr admin.pem

ca-key.pem:
	openssl genrsa -out ca-key.pem 2048
ca.pem:
	openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

apiserver-key.pem:
	openssl genrsa -out apiserver-key.pem 2048

apiserver.csr:
	openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf

apiserver.pem:
	openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

worker-key.pem:
	openssl genrsa -out worker-key.pem 2048

worker.csr:
	openssl req -new -key worker-key.pem -out worker.csr -subj "/CN=kube-worker"

worker.pem:
	openssl x509 -req -in worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker.pem -days 365

admin-key.pem:
	openssl genrsa -out admin-key.pem 2048

admin.csr:
	openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"

admin.pem:
	openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365

clean:
	-rm -f *.pem *.csr *.srl
