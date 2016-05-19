#cloud-config

write_files:
  - path: /etc/flannel/options.env
    permission: 0600
    owner: root
    content: |
      FLANNELD_IFACE=$advertise_ip
      FLANNELD_ETCD_ENDPOINTS=$etcd_endpoints

coreos:
  update:
    reboot-strategy: $reboot_strategy
  units:
    - name: flanneld.service
      drop-ins:
        - name: 40-ExecStartPre-symlink.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/ln -sf /etc/flannel/options.env /run/flannel/options.env
      command: start
    - name: docker.service
      drop-ins:
        - name: 40-flannel.conf
          content: |
            [Unit]
            Requires=flanneld.service
            After=flanneld.service
      command: start
    - name: kubelet.service
      content : |
        [Service]
        ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests

        Environment=KUBELET_VERSION=v1.2.4_coreos.cni.1
        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=http://127.0.0.1:8080 \
          --network-plugin-dir=/etc/kubernetes/cni/net.d \
          --register-schedulable=false \
          --allow-privileged=true \
          --config=/etc/kubernetes/manifests \
          --hostname-override=10.0.0.2
        Restart=always
        RestartSec=10
        [Install]
        WantedBy=multi-user.target 
