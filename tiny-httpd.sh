#! /bin/bash
# build tiny configuration with Apache httpd with php support
# version 2024.03

# set all parameters as variables
LIBDIR="/srv/lib"
WEBDIR="/srv/www"
CNAME="httpd"

# make sure all required software is present
sudo apt-get install -y ntp docker.io >/dev/null 2>/dev/null

# stop and remove the old version of this container as well as unused ones
docker stop "$CNAME" 2>/dev/null
docker rm "$CNAME" 2>/dev/null
docker container prune -f 2>/dev/null

# make sure web directory exist
sudo rm -r -f  $WEBDIR
sudo mkdir -p $WEBDIR
sudo chmod 777 $WEBDIR

# copy web content
cat >"$WEBDIR/index.php" <<EOF
<HTML>
<HEAD>
    <TITLE>Hello</TITLE>
</HEAD>
<BODY>
<?php
\$ip_server = \$_SERVER['SERVER_ADDR'];
echo "Hello from \$ip_server";
?>
</BODY>
EOF

sudo chmod 744 $WEBDIR/*.{html,php} 2>/dev/null

# start the container
docker run \
  --hostname "$CNAME" \
  --publish "8080:80" \
  --volume "/srv/www:/var/www/html" \
  --name "$CNAME" \
  --detach \
  php:apache

