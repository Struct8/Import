# Lab function: an OCI function calls AWS S3 through a cldmn_workload_identity
# component (lab_caller.py). Built by the repository's seed in the lab canvas
# (terraform_data.seed_<repository>) from this folder of Struct8/Import, branch
# lab/oci-aws-caller. Same base images as backend/AgentOCI.
FROM fnproject/python:3.12-0.1.128-dev AS build
WORKDIR /function
COPY requirements.txt .
RUN pip3 install --target /python/ --no-cache-dir -r requirements.txt \
    && chmod -R o+r /python
COPY func.py lab_caller.py ./

FROM fnproject/python:3.12-0.1.128
WORKDIR /function
COPY --from=build /python /python
COPY --from=build /function /function
RUN chmod -R o+r /function
ENV PYTHONPATH=/function:/python
ENTRYPOINT ["/python/bin/fdk", "/function/func.py", "handler"]
