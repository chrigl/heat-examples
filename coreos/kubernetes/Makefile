all:
	$(MAKE) -C tls all
	$(MAKE) -C kubernetes all

clean: clean_tls clean_kubernetes

clean_tls:
	$(MAKE) -C tls clean

clean_kubernetes:
	$(MAKE) -C kubernetes clean
