# Dockerfile for building a development image.
# The built image contains all required pip and apt packages for building and
# running PyTorch and PyTorch/XLA. The image doesn't contain any source code.
FROM summerwind/actions-runner-dind

RUN sudo pip3 install ansible

COPY . /ansible
WORKDIR /ansible

# List Asnible tasks to apply for the dev image.
ENV TAGS="bazel,configure_env,install_deps"

ARG ansible_vars="stage=build accelerator=tpu arch=amd64"
RUN sudo ansible-playbook playbook.yaml -e "stage=build" -e "${ansible_vars}" --tags "${TAGS}"
RUN sudo ansible-playbook playbook.yaml -e "stage=release" -e "${ansible_vars}" --tags "${TAGS}"

RUN sudo usermod -aG sudo runner

USER runner
