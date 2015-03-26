#!/bin/bash
set -ex
export TOP=$(readlink -f ${TOP:-.})
export SITEPACKAGES=${SITEPACKAGES:-.}
export PROJECT=venv_update
NCPU=$(getconf _NPROCESSORS_CONF)

if python -c 'import platform; exit(not(platform.python_implementation() == "PyPy"))'; then
    # coverage under pypy takes too dang long:
    #   https://bitbucket.org/pypy/pypy/issue/1871/10x-slower-than-cpython-under-coverage#comment-14404182
    PYPY=true
else
    PYPY=false
fi

if $PYPY; then
    # Having issues with memory, let's try reducing CPUs by half
    py.test -n $((NCPU / 3)) \
        "$@" $TOP/tests $SITEPACKAGES/${PROJECT}.py
else
    coverage erase
    py.test -n $NCPU \
        --cov --cov-config=$TOP/.coveragerc --cov-report='' \
        "$@" $TOP/tests $SITEPACKAGES/${PROJECT}.py
    coverage combine
    coverage report --rcfile=$TOP/.coveragerc --fail-under 94  # FIXME: should be 100
fi
