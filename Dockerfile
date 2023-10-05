FROM summerwind/actions-runner-dind

RUN pip install ansible

COPY . /ansible
WORKDIR /ansible

# List Asnible tasks to apply for the dev image.
ENV TAGS="bazel,configure_env,install_deps"

ARG ansible_vars=accelerator=tpu
RUN ansible-playbook playbook.yaml -e "stage=build" -e "${ansible_vars}" --tags "${TAGS}"
RUN ansible-playbook playbook.yaml -e "stage=release" -e "${ansible_vars}" --tags "${TAGS}"
