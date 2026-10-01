# /etc/tower/conf.d/execution_environments.py
import os

_ee = os.environ.get('AWX_EE_IMAGE', 'quay.io/ansible/awx-ee:latest')

GLOBAL_JOB_EXECUTION_ENVIRONMENTS = [{'name': 'AWX EE', 'image': _ee}]
CONTROL_PLANE_EXECUTION_ENVIRONMENT = _ee
