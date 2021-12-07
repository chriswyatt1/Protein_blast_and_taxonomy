FROM mambaorg/micromamba:0.13.1

COPY conda.yml conda.here.yml

RUN micromamba install -y -n base -f conda.here.yml && \
    micromamba clean --all --yes
