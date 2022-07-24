FROM ubuntu
ENV ANSIBLE_FORCE_COLOR=1
ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"
ENV PATH $PATH:/opt/google-cloud-sdk/bin
ENV PATH "/root/.krew/bin:$PATH"
ENV SHELL /bin/zsh
ENV PACKAGES="\
git \
gcc \
gnupg \
rsync \
ssh \
libyaml-dev \
wget \
docker \
curl \
apt-transport-https \
ca-certificates \ 
python3 \
software-properties-common \
zsh \
python3-pip \
maven \
npm \
openjdk-17-jdk \
zsh-syntax-highlighting \ 
zsh-autosuggestions \
vim \
docker.io \
unzip \
fzf \
jq \
sshpass \
less \
golang \
"
WORKDIR /tmp
# Copy config files
COPY .zshrc tests/goss.yaml requirements.txt ./
RUN apt-get update && apt-get -y upgrade && apt-get install --no-install-recommends -y ${PACKAGES} && \
    add-apt-repository --yes --update ppa:ansible/ansible && apt-get update && \ 
    apt-get install -y ansible && \
    # Pip packages
    python3 -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    # Kubernetes tooling
    curl -fsSLo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64 && chmod +x ./kind && mv ./kind /usr/local/bin/kind && \
    curl -fsSLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz" && \
    tar -zxvf krew-linux_amd64.tar.gz && chmod +x krew-linux_amd64 && mv krew-linux_amd64 /usr/local/bin/kubectl-krew && \
    kubectl krew install popeye neat stern slice sick-pods blame tree ctx ns && \
    curl -sSL "https:///raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && mv kustomize /usr/local/bin/ && \
    curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=1.14.1 sh - && cp istio-1.14.1/bin/istioctl /usr/local/bin && \
    curl -sSLo /usr/local/bin/switcher https://github.com/danielfoehrKn/kubeswitch/releases/download/0.7.0/switcher_linux_amd64 && chmod +x /usr/local/bin/switcher && \
    # Terraform tools
    curl -sSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    curl -sSLo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz && \
    tar -xzf terraform-docs.tar.gz && chmod +x terraform-docs && mv terraform-docs /usr/local/bin/terraform-docs && \
    curl -sSlo vault.zip https://releases.hashicorp.com/vault/1.11.0/vault_1.11.0_linux_arm64.zip && unzip vault.zip && mv vault /usr/local/bin/vault && chmod +x /usr/local/bin/vault && \
    curl -sSlo packer.zip https://releases.hashicorp.com/packer/1.8.2/packer_1.8.2_linux_amd64.zip && unzip packer.zip && mv packer /usr/local/bin/packer && chmod +x /usr/local/bin/packer && \
    curl -sSlo terraform.zip https://releases.hashicorp.com/terraform/1.2.5/terraform_1.2.5_linux_amd64.zip && unzip terraform.zip && mv terraform /usr/local/bin/terraform && chmod +x /usr/local/bin/terraform && \ 
    curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash && \
    curl -L https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh | bash && \
    # Helm and plugins
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && helm plugin install https://github.com/vbehar/helm3-unittest && \
    wget -q -O helm-docs.tar.gz https://github.com/norwoodj/helm-docs/releases/download/v1.10.0/helm-docs_1.10.0_Linux_x86_64.tar.gz && tar -xvf helm-docs.tar.gz && mv helm-docs /usr/local/bin && chmod +x /usr/local/bin/helm-docs && \
    wget -q -O helm-changelog.tar.gz https://github.com/mogensen/helm-changelog/releases/download/v0.0.1/helm-changelog_0.0.1_linux_amd64.tar.gz && tar -xvf helm-changelog.tar.gz && mv helm-changelog /usr/local/bin && chmod +x /usr/local/bin/helm-changelog && \
    helm plugin install https://github.com/databus23/helm-diff && \
    # Development Tools
    wget -q -o go.tar.gz https://go.dev/dl/go1.17.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.17.3.linux-amd64.tar.gz && \
    curl -sSLo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && install skaffold /usr/local/bin/ && \
    curl -sSLo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd && \
    curl -sSLo /usr/local/bin/kubectl-argo-rollouts https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64 && chmod +x /usr/local/bin/kubectl-argo-rollouts && \

    # GCP tooling
    curl https://sdk.cloud.google.com > install.sh && bash install.sh --disable-prompts && mv /root/google-cloud-sdk /opt/google-cloud-sdk && \
    gcloud components install nomos kpt gsutil gke-gcloud-auth-plugin && \
    # Azure tooling
    curl -sSL https://aka.ms/InstallAzureCLIDeb | bash && az extension add --name azure-devops && \
    # Utilities
    curl -sSLo dive.tar.gz https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.tar.gz && tar -xvf dive.tar.gz && mv dive /usr/local/bin/dive && chmod +x /usr/local/bin/dive && \
    curl -sSLo opa https://openpolicyagent.org/downloads/v0.41.0/opa_linux_amd64_static && chmod +x opa && mv opa /usr/local/bin/opa && \
    curl -fsSLO https://github.com/open-policy-agent/gatekeeper/releases/download/v3.8.1/gator-v3.8.1-linux-amd64.tar.gz && tar -xvf gator-v3.8.1-linux-amd64.tar.gz && mv gator /usr/local/bin && chmod +x /usr/local/bin/gator && \
    wget -q -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.8.0/hadolint-Linux-x86_64 && mv hadolint /usr/local/bin && chmod +x /usr/local/bin/hadolint && \
    wget -q https://github.com/mikefarah/yq/releases/download/v4.16.2/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq && \
    curl -fsSL https://goss.rocks/install | sh && \
    curl -sSLo k6.tar.gz https://github.com/grafana/k6/releases/download/v0.38.3/k6-v0.38.3-linux-amd64.tar.gz && tar -xvf k6.tar.gz && mv k6-v0.38.3-linux-amd64/k6 /usr/local/bin/k6 && chmod +x /usr/local/bin/k6 && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && mv /tmp/.zshrc /root/.zshrc && \
    mkdir ~/completions && istioctl collateral --zsh -o ~/completions && \
    curl -sSLo operator-sdk https://github.com/operator-framework/operator-sdk/releases/download/v1.21.0/operator-sdk_linux_amd64 && chmod +x operator-sdk && mv operator-sdk /usr/local/bin/operator-sdk && \
    # Run Tests
    goss v && \
    # Clean up
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
