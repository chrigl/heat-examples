all: master/cloudinit.yaml worker/cloudinit.yaml

master/cloudinit.yaml:
	python3 ./gen_writefiles.py -c master/write_files.json -t master/cloudinit.yaml.tpl -f master/cloudinit.yaml

worker/cloudinit.yaml:
	python3 ./gen_writefiles.py -c worker/write_files.json -t worker/cloudinit.yaml.tpl -f worker/cloudinit.yaml

clean:
	-rm -f master/cloudinit.yaml worker/cloudinit.yaml
