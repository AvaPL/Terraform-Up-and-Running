#!/bin/bash

echo "Hello, World from `hostname`" > index.html
nohup busybox httpd -f -p 8080 &