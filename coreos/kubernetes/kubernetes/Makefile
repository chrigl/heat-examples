all: master-cloudinit.yaml

master-cloudinit.yaml:
	python3 ./gen_writefiles.py -c write_files.json -t master-cloudinit.yaml.tpl -f master-cloudinit.yaml

clean:
	-rm -f master-cloudinit.yaml
