#!/bin/sh

echo GOROOT=${GOROOT} >> /tmp/beryl
echo GOPATH=${GOPATH} >> /tmp/beryl

go build ${1}

