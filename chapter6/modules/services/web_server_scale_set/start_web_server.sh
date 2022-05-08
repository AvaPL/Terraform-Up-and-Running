#!/bin/bash

echo "<h1>${server_message} from `hostname`</h1>" >> index.html
nohup busybox httpd -f -p ${port} &