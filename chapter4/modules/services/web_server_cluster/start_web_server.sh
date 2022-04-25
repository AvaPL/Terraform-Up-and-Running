#!/bin/bash

echo "<h1>Hello, World from `hostname`</h1>" >> index.html
echo "<p>MySQL: ${mysql_fqdn}</p>" >> index.html
nohup busybox httpd -f -p ${port} &