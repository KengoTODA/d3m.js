#!/bin/sh

# compile
coffee -cb -o . .

# create documents
pushd jsdoc-toolkit
./jsrun.sh ../d3m.js -t=templates/jsdoc/ -d=../docs
popd

