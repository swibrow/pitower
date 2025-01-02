
CLUSTER := pitower

.PHONY: all

# Variables
export TALOSCONFIG := "talosconfig"

# Generate cluster configuration
config:
    sops -d ./secrets.sops.yaml > ./secrets.yaml
    talosctl gen config \
        pitower \
        https://192.168.0.200:6443 \
        --with-secrets ./secrets.yaml \
        --with-examples=true \
        --config-patch-control-plane @patches/controlplane.patch \
        --config-patch @patches/general.patch \
        --output ./clusterconfig \
        --force

# Patch configurations for different nodes
patch:
    #!/usr/bin/env bash
    cd ./clusterconfig
    talosctl machineconfig patch ./controlplane.yaml --patch @../patches/nodes/master-01.patch --output master-01.yaml
    talosctl machineconfig patch ./controlplane.yaml --patch @../patches/nodes/master-02.patch --output master-02.yaml
    talosctl machineconfig patch ./controlplane.yaml --patch @../patches/nodes/master-03.patch --output master-03.yaml
    talosctl machineconfig patch ./worker.yaml --patch @../patches/nodes/worker-01.patch --output worker-01.yaml
    talosctl machineconfig patch ./worker.yaml --patch @../patches/nodes/worker-02.patch --output worker-02.yaml
    talosctl machineconfig patch ./worker.yaml --patch @../patches/nodes/worker-03.patch --output worker-03.yaml
    talosctl machineconfig patch ./worker.yaml --patch @../patches/nodes/worker-04.patch --output worker-04.yaml
    talosctl machineconfig patch ./worker.yaml --patch @../patches/nodes/worker-05.patch --output worker-05.yaml
    talosctl machineconfig patch ./worker.yaml --patch @../patches/nodes/worker-06.patch --output worker-06.yaml

# Initialize cluster configuration
init:
    #!/usr/bin/env bash
    cd ./clusterconfig
    talosctl apply-config --insecure --nodes 192.168.0.202 --file ./master-02.yaml
    talosctl apply-config --insecure --nodes 192.168.0.203 --file ./master-03.yaml
    talosctl config endpoint 192.168.0.201 192.168.0.202 192.168.0.203

# Bootstrap cluster
bootstrap:
    cd ./clusterconfig && talosctl kubeconfig --nodes 192.168.0.200 --force

# Install and configure Flux
flux:
    brew install fluxcd/tap/flux
    flux install
    just ../
    kubectl apply -f ../kubernetes/apps/flux-system/bootstrap.yaml

# Apply control plane configurations
apply-controlplanes:
    #!/usr/bin/env bash
    cd ./clusterconfig
    talosctl apply-config --endpoints 192.168.0.201 --nodes 192.168.0.201 --file ./master-01.yaml
    talosctl apply-config --endpoints 192.168.0.202 --nodes 192.168.0.202 --file ./master-02.yaml
    talosctl apply-config --endpoints 192.168.0.203 --nodes 192.168.0.203 --file ./master-03.yaml

# Apply worker configurations
apply-workers:
    #!/usr/bin/env bash
    cd ./clusterconfig
    for i in {1..4}; do
        talosctl apply-config --nodes "192.168.0.21$i" --file "./worker-0$i.yaml"
    done

# Apply single worker configuration
apply-worker worker_num:
    cd ./clusterconfig && talosctl apply-config --nodes "192.168.0.21{{worker_num}}" --file "./worker-0{{worker_num}}.yaml" --wait

# Reboot control planes
reboot-controlplanes:
    #!/usr/bin/env bash
    for i in {1..3}; do
        talosctl reboot --endpoints "192.168.0.20$i" --nodes "192.168.0.20$i" --wait
    done

# Reboot workers
reboot-workers:
    #!/usr/bin/env bash
    for i in {1..4}; do
        talosctl reboot --nodes "192.168.0.21$i" --wait
    done

# Apply addons
addons:
    kustomize build ./addons --enable-helm | kubectl apply -f -

# Reset node
reset node_num:
    talosctl reset \
        --system-labels-to-wipe=STATE \
        --system-labels-to-wipe=EPHEMERAL \
        --system-labels-to-wipe=META \
        --reboot \
        --graceful \
        -n "192.168.0.2{{node_num}}"

# Nuke workers
nuke-workers:
    #!/usr/bin/env bash
    for i in 1 2 3 5 6; do
        talosctl reset \
            --system-labels-to-wipe=STATE \
            --system-labels-to-wipe=EPHEMERAL \
            --system-labels-to-wipe=META \
            --graceful=false \
            --reboot \
            --wait=false \
            --nodes "192.168.0.21$i"
    done

# Nuke control planes
nuke-controlplanes:
    #!/usr/bin/env bash
    for i in {1..3}; do
        talosctl reset \
            --system-labels-to-wipe=STATE \
            --system-labels-to-wipe=EPHEMERAL \
            --system-labels-to-wipe=META \
            --graceful=false \
            --reboot \
            --wait=false \
            --nodes "192.168.0.20$i"
    done

# Upgrade control planes
upgrade-controlplanes:
    #!/usr/bin/env bash
    export IMAGE="factory.talos.dev/installer/a862538d0862e8ad5b17fadc2b56599677101537b3f75926085d8cbff4a411b9:v1.9.1"
    for i in {1..3}; do
        talosctl upgrade \
            --image "$IMAGE" \
            --nodes "192.168.0.20$i" \
            --preserve \
            --wait
    done

# Upgrade AMD workers
upgrade-workers-amd:
    #!/usr/bin/env bash
    export IMAGE="factory.talos.dev/installer/f19ad7b4a5d29151f3a59ef2d9c581cf89e77142e52f0abb5022e8f0b95ad0b9:v1.9.1"
    for i in {1..3}; do
        talosctl upgrade \
            --image "$IMAGE" \
            --nodes "192.168.0.21$i" \
            --preserve \
            --wait
    done

# Upgrade Intel workers
upgrade-workers-intel:
    #!/usr/bin/env bash
    export IMAGE="factory.talos.dev/installer/97bf8e92fc6bba0f03928b859c08295d7615737b29db06a97be51dc63004e403:v1.9.1"
    talosctl upgrade \
        --image "$IMAGE" \
        --nodes "192.168.0.214" \
        --preserve \
        --wait

# Upgrade Raspberry Pi workers
upgrade-workers-raspberrypi:
    #!/usr/bin/env bash
    export IMAGE="factory.talos.dev/installer/a862538d0862e8ad5b17fadc2b56599677101537b3f75926085d8cbff4a411b9:v1.9.1"
    talosctl upgrade \
        --image "$IMAGE" \
        --preserve \
        --wait

# Get image IDs
image-id:
    #!/usr/bin/env bash
    cd ./extensions
    for file in amd.yaml intel.yaml rpi-poe.yaml; do
        basename="${file%.yaml}"
        id=$(curl -sX POST --data-binary "@$file" https://factory.talos.dev/schematics | jq -r .id)
        echo "$basename: $id"
    done