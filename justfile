#
# Run these recipes using `just` - https://github.com/casey/just.
#

# List recipes
list:
    @just --list --unsorted

####################
# some conveniences:

# ssh to the gizo
ssh-gizo user="carueda" server="gizo.shore.mbari.org":
    ssh {{user}}@{{server}}

# Package and transfer complete code to gizo
to-gizo user="carueda" server="gizo.shore.mbari.org": tgz
    #!/usr/bin/env bash
    HASH=$(git rev-parse --short HEAD)
    echo "$HASH" > HASH
    scp HASH pypam-based-processing_${HASH}.tgz {{user}}@{{server}}:/PAM_Analysis/pypam-space/processing_our_data/

# Package for subsequent code transfer to gizo
tgz:
    #!/usr/bin/env bash
    HASH=$(git rev-parse --short HEAD)
    git archive ${HASH} -o pypam-based-processing_${HASH}.tgz --prefix=pypam-based-processing/

# TODO review `--json-base-dir` value per subquent changes to support cloud processing,

# Run main (on gizo)
main-gizo date="20220902" output_dir="/PAM_Analysis/pypam-space/test_output/daily":
    PYTHONPATH=. python src/main.py \
                 --json-base-dir=json \
                 --date={{date}} \
                 --sensitivity-uri=misc/icListen1689_sensitivity_hms256kHz.nc \
                 --subset-to 10 100000 \
                 --audio-path-map-prefix="s3://pacific-sound-256khz-2022~file:///PAM_Archive/2022" \
                 --output-dir={{output_dir}}

# Run main (on gizo) with some initial test jsons
main-gizo-test *more_args="":
    PYTHONPATH=. python src/main.py \
                 --json-base-dir=tests/json \
                 --date=20220902 \
                 --sensitivity-uri=misc/icListen1689_sensitivity_hms256kHz.nc \
                 --subset-to 10 100000 \
                 --audio-base-dir=tests/wav \
                 --audio-path-map-prefix="s3://pacific-sound-256khz-2022~file:///PAM_Archive/2022" \
                 --output-dir=/PAM_Analysis/pypam-space/test_output/daily \
                 {{more_args}}

#                 --save-segment-result \
#                 --save-extracted-wav \

# Run main (on my mac)
main-mac *more_args="":
    PYTHONPATH=. python src/main.py \
                 --json-base-dir=tests/json \
                 --audio-path-prefix=/Volumes \
                 --date=20220902 \
                 --sensitivity-uri=misc/icListen1689_sensitivity_hms256kHz.nc \
                 --gen-csv \
                 --subset-to 10 100000 \
                 --output-dir=output \
                 {{more_args}}

#                 --max-segments=5 \
#                 --save-segment-result \
#                 --output-dir=/Volumes/PAM_Analysis/pypam-space/test_output \

# Basic test for cloud processing
main-cloud-basic-test max_segments="1":
    #!/usr/bin/env bash
    export DATE="20220902"
    export MAX_SEGMENTS={{max_segments}}
    export PYTHONPATH=.
    python src/main_cloud.py

# Run main
main *args="":
    PYTHONPATH=. python src/main.py {{args}}

##############
# development:

# A convenient recipe for development
dev: check test format

# As the dev recipe plus pylint; good to run before committing changes
all: dev pylint

# Create virtual environment
virtenv:
    python3 -m venv virtenv

# Install dependencies
setup:
    pip3 install -r requirements.txt
    pip3 install -i https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ lifewatch-pypam==0.1.9b0
    mypy --install-types

# Do static type checking (not very strict)
check:
    python -m mypy .

# Install std types for mypy
install-types:
    python -m mypy --install-types

# Do snapshot-update
snapshot-update:
    python -m pytest --snapshot-update

# Run tests
test *options="":
    python -m pytest {{options}}

# Format source code
format:
    python -m ufmt format .

# Format source code using ruff
ruff:
    ruff --fix .

# Run pylint
pylint:
    python -m pylint src

# With prior running of:
#   python -m pip install --upgrade build
# Create dist
dist:
    python -m build
