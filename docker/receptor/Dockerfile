# Receptor node for AWX on Docker Compose.
#
# awx-ee already ships receptor and ansible-runner; podman is added so
# ansible-runner can start each job's execution-environment container
# (AWX runs every non-Kubernetes job with podman process isolation).
ARG AWX_EE_IMAGE=quay.io/ansible/awx-ee:24.6.1
FROM ${AWX_EE_IMAGE}

USER root
RUN dnf install -y podman fuse-overlayfs \
 && dnf clean all \
 && rm -rf /var/cache/dnf

CMD ["receptor", "--config", "/etc/receptor/receptor.conf"]
