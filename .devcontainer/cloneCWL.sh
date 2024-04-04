#!/bin/sh

CWL_BASE_URL=https://github.com/common-workflow-language

if [ -d cwl-v1.0 ]; then
    git -C cwl-v1.0 pull
else
    git clone --depth 1 $CWL_BASE_URL/common-workflow-language.git cwl-v1.0
fi

if [ -d cwl-v1.1 ]; then
    git -C cwl-v1.1 pull
else
    git clone --depth 1 $CWL_BASE_URL/cwl-v1.1.git cwl-v1.1
fi

if [ -d cwl-v1.2 ]; then
    git -C cwl-v1.2 pull
else
    git clone --depth 1 $CWL_BASE_URL/cwl-v1.2.git cwl-v1.2
fi
