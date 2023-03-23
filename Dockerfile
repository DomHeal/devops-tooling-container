FROM ubuntu:22.10
ENV ANSIBLE_FORCE_COLOR=1
ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"
ENV PATH $PATH:/opt/google-cloud-sdk/bin
ENV PATH "/root/.krew/bin:$PATH"
ENV SHELL /bin/zsh
# renovate: datasource=github-releases depName=mikefarah/yq
ENV YQ_VERSION=v4.32.2
# renovate: datasource=github-releases depName=hadolint/hadolint
ENV HADOLINT_VERSION=v2.12.0
# renovate: datasource=github-releases depName=wagoodman/dive extractVersion=^v(?<version>.*)$
ENV DIVE_VERSION=0.10.0
# renovate: datasource=github-releases depName=hashicorp/vault extractVersion=^v(?<version>.*)$
ENV VAULT_VERSION=1.13.0
# renovate: datasource=github-releases depName=hashicorp/terraform extractVersion=^v(?<version>.*)$
ENV TERRAFORM_VERSION=1.4.2
# renovate: datasource=github-releases depName=hashicorp/packer extractVersion=^v(?<version>.*)$
ENV PACKER_VERSION=1.8.6
# renovate: datasource=github-releases depName=norwoodj/helm-docs extractVersion=^v(?<version>.*)$
ENV HELMDOCS_VERSION=1.11.0
# renovate: datasource=github-releases depName=grafana/k6 extractVersion=^v(?<version>.*)$
ENV K6_VERSION=0.43.1
# renovate: datasource=github-releases depName=kubeshark/kubeshark
ENV KUBESHARK_VERSION=37.0
# renovate: datasource=github-releases depName=operator-framework/operator-sdk
ENV OPERATORSDK_VERSION=v1.28.0
# renovate: datasource=github-releases depName=kubernetes-sigs/kind
ENV KIND_VERSION=v0.17.0
# renovate: datasource=github-releases depName=open-policy-agent/gatekeeper
ENV GATOR_VERSION=v3.11.0
# renovate: datasource=github-releases depName=open-policy-agent/opa
ENV OPA_VERSION=v0.50.2

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
sshpass \
less \
golang \
autossh \
make \
language-pack-en \
ansible \
"
WORKDIR /tmp
# Copy config files
COPY .zshrc tests/goss.yaml requirements.txt ./
RUN apt-get update && apt-get -y upgrade && apt-get install --no-install-recommends -y ${PACKAGES} && \
    pip3 install --no-cache-dir -r requirements.txt && \
    curl -fsSLo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64 && chmod +x ./kind && mv ./kind /usr/local/bin/kind && \
    curl -fsSLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz" && \
    tar -zxvf krew-linux_amd64.tar.gz && chmod +x krew-linux_amd64 && mv krew-linux_amd64 /usr/local/bin/kubectl-krew && \
    kubectl krew install neat stern slice tree ctx ns mc && \
    curl -sSL "https:///raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && mv kustomize /usr/local/bin/ && \
    curl -sSL https://istio.io/downloadIstio | sh - && cp istio-*/bin/istioctl /usr/local/bin && \
    # Terraform tools
    curl -sSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    curl -sSLo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz && \
    tar -xzf terraform-docs.tar.gz && chmod +x terraform-docs && mv terraform-docs /usr/local/bin/terraform-docs && \
    curl -sSlo vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_arm64.zip && unzip vault.zip && mv vault /usr/local/bin/vault && chmod +x /usr/local/bin/vault && \
    curl -sSlo packer.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && unzip packer.zip && mv packer /usr/local/bin/packer && chmod +x /usr/local/bin/packer && \
    curl -sSlo terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip terraform.zip && mv terraform /usr/local/bin/terraform && chmod +x /usr/local/bin/terraform && \ 
    curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash && \
    curl -L https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh | bash && \
    # Helm and plugins
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && helm plugin install https://github.com/quintush/helm-unittest && \
    curl -sSLo helm-docs.tar.gz https://github.com/norwoodj/helm-docs/releases/download/v${HELMDOCS_VERSION}/helm-docs_${HELMDOCS_VERSION}_Linux_x86_64.tar.gz && tar -xvf helm-docs.tar.gz && mv helm-docs /usr/local/bin && chmod +x /usr/local/bin/helm-docs && \
    curl -sSLo helm-changelog.tar.gz https://github.com/mogensen/helm-changelog/releases/download/v0.0.1/helm-changelog_0.0.1_linux_amd64.tar.gz && tar -xvf helm-changelog.tar.gz && mv helm-changelog /usr/local/bin && chmod +x /usr/local/bin/helm-changelog && \
    helm plugin install https://github.com/databus23/helm-diff && \
    # Development Tools
    curl -sSLo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && install skaffold /usr/local/bin/ && \
    curl -sSLo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd && \
    curl -sSLo /usr/local/bin/kubectl-argo-rollouts https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64 && chmod +x /usr/local/bin/kubectl-argo-rollouts && \
    # GCP tooling
    curl https://sdk.cloud.google.com > install.sh && bash install.sh --disable-prompts && mv /root/google-cloud-sdk /opt/google-cloud-sdk && \
    gcloud components install nomos kpt gsutil gke-gcloud-auth-plugin && \
    # Azure tooling
    curl -sSL https://aka.ms/InstallAzureCLIDeb | bash && az extension add --name azure-devops && \
    # Utilities
    curl -sSLo dive.tar.gz https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz && tar -xvf dive.tar.gz && mv dive /usr/local/bin/dive && chmod +x /usr/local/bin/dive && \
    curl -sSLo /usr/local/bin/opa https://openpolicyagent.org/downloads/${OPA_VERSION}/opa_linux_amd64_static && chmod +x /usr/local/bin/opa && \
    curl -fsSLO https://github.com/open-policy-agent/gatekeeper/releases/download/${GATOR_VERSION}/gator-${GATOR_VERSION}-linux-amd64.tar.gz && tar -xvf gator-${GATOR_VERSION}-linux-amd64.tar.gz && mv gator /usr/local/bin && chmod +x /usr/local/bin/gator && \
    curl -sSLo /usr/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 && chmod +x /usr/bin/yq && \
    curl -fsSL https://goss.rocks/install | sh && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    mv /tmp/.zshrc /root/.zshrc && \
    mkdir ~/completions && istioctl collateral --zsh -o ~/completions && \
    curl -sSLo operator-sdk https://github.com/operator-framework/operator-sdk/releases/download/${OPERATORSDK_VERSION}/operator-sdk_linux_amd64 && chmod +x operator-sdk && mv operator-sdk /usr/local/bin/operator-sdk && \
    curl -sSLo /usr/local/bin/kubeshark https://github.com/kubeshark/kubeshark/releases/download/${KUBESHARK_VERSION}/kubeshark_linux_amd64 && chmod +x /usr/local/bin/kubeshark && \
    sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin && \
    # Run Tests
    goss v && \
    # Clean up
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
