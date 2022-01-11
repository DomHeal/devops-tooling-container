FROM ubuntu
ENV ANSIBLE_FORCE_COLOR=1
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
default-jdk \
zsh-syntax-highlighting \ 
zsh-autosuggestions \
vim \
docker.io \
unzip \
language-pack-en \
fzf \
jq \
"
WORKDIR /tmp

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone
RUN apt-get update && apt-get -y upgrade && apt-get install -y ${PACKAGES}
# Hashicorp tools
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 
RUN apt-get update && apt-get -y upgrade && apt-get install -y terraform packer vault

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Ansible and Tooling
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install -r /tmp/requirements.txt

# Kubernetes
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN wget -O kubectx.tar.gz https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx_v0.9.4_linux_x86_64.tar.gz && tar -xvf kubectx.tar.gz && mv kubectx /usr/local/bin && chmod +x /usr/local/bin/kubectx
RUN wget -O kubens.tar.gz https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens_v0.9.4_linux_x86_64.tar.gz && tar -xvf kubens.tar.gz && mv kubens /usr/local/bin && chmod +x /usr/local/bin/kubens
# Terraform tooling
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
RUN curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz && \
    tar -xzf terraform-docs.tar.gz && chmod +x terraform-docs && mv terraform-docs /usr/local/bin/terraform-docs && \
    wget -O kubelinter.tar.gz https://github.com/stackrox/kube-linter/releases/download/0.2.5/kube-linter-linux.tar.gz && tar -xvf kubelinter.tar.gz && mv kube-linter /usr/local/bin/kube-linter && chmod +x /usr/local/bin/kube-linter

# Azure
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && az extension add --name azure-devops
# Istioctl
RUN curl -L https://istio.io/downloadIstio | sh -
# GO
RUN wget -o go.tar.gz https://go.dev/dl/go1.17.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.17.3.linux-amd64.tar.gz
# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && helm plugin install https://github.com/vbehar/helm3-unittest
RUN wget -O helm-docs.tar.gz https://github.com/norwoodj/helm-docs/releases/download/v1.5.0/helm-docs_1.5.0_Darwin_x86_64.tar.gz && tar -xvf helm-docs.tar.gz && mv helm-docs /usr/local/bin && chmod +x /usr/local/bin/helm-docs
RUN wget -O helm-changelog.tar.gz https://github.com/mogensen/helm-changelog/releases/download/v0.0.1/helm-changelog_0.0.1_linux_amd64.tar.gz && tar -xvf helm-changelog.tar.gz && mv helm-changelog /usr/local/bin && chmod +x /usr/local/bin/helm-changelog
RUN helm plugin install https://github.com/databus23/helm-diff

# Skaffold
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && install skaffold /usr/local/bin/
# Flux Cli
RUN curl -s https://fluxcd.io/install.sh | bash
# Argocd
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd

# Gcloud
RUN curl https://sdk.cloud.google.com > install.sh && bash install.sh --disable-prompts
ENV PATH $PATH:/root/google-cloud-sdk/bin
RUN gcloud components install nomos && gcloud components install kpt

RUN curl -Lo stern https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64 && mv stern /usr/local/bin/
# Kutomize
RUN curl -s "https:///raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && mv kustomize /usr/local/bin/

# hadolint
RUN wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.8.0/hadolint-Linux-x86_64 && mv hadolint /usr/local/bin && chmod +x /usr/local/bin/hadolint

# yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.16.2/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Copy config files
COPY .zshrc /root/.zshrc

# Goss tests
RUN curl -fsSL https://goss.rocks/install | sh
COPY tests/goss.yaml ./
RUN goss v && rm -rf goss.yaml
# cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
