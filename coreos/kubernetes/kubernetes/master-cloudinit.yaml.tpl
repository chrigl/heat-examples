#cloud-config

write_files:

coreos:
  update:
    reboot-strategy: $reboot_strategy
