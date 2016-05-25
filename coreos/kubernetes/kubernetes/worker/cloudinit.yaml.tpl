#cloud-config

write_files:
  - path: /etc/environment-kubelet
    permissions: 0600
    owner: root
    content: |
      KUBELET_VERSION=$hyperkube_version
  - path: /etc/flannel/options.env
    permissions: 0600
    owner: root
    content: |
      FLANNELD_IFACE=$flanneld_iface
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
        EnvironmentFile=/etc/environment
        EnvironmentFile=/etc/environment-kubelet
        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=https://10.0.0.2 \
          --network-plugin-dir=/etc/kubernetes/cni/net.d \
          --register-node=true \
          --allow-privileged=true \
          --config=/etc/kubernetes/manifests \
          --hostname-override=${COREOS_PRIVATE_IPV4} \
          --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml \
          --tls-cert-file=/etc/kubernetes/ssl/worker.pem \
          --tls-private-key-file=/etc/kubernetes/ssl/worker-key.pem
        Restart=always
        RestartSec=10
        [Install]
        WantedBy=multi-user.target
      command: start
      enable: true
