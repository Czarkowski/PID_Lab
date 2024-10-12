#! /bin/bash
# build tiny configuration with Apache httpd with php support
# version 2024.03

# set all parameters as variables
LIBDIR="/srv/lib"
WEBDIR1="/srv/www1"
WEBDIR2="/srv/www2"
CNAME1="httpd1"
CNAME2="httpd2"

# make sure all required software is present
sudo apt-get install -y ntp docker.io >/dev/null 2>/dev/null

# stop and remove the old version of this container as well as unused ones
docker stop "$CNAME1" 2>/dev/null
docker rm "$CNAME1" 2>/dev/null

docker stop "$CNAME2" 2>/dev/null
docker rm "$CNAME2" 2>/dev/null

docker container prune -f 2>/dev/null

# make sure web directory exist
sudo rm -r -f  $WEBDIR1 $WEBDIR2
sudo mkdir -p $WEBDIR1 $WEBDIR2
sudo chmod 777 $WEBDIR1
sudo chmod 777 $WEBDIR2

# copy web content
cat >"$WEBDIR1/index.php" <<EOF
<HTML>
<HEAD>
    <TITLE>Hello from Instance 1</TITLE>
</HEAD>
<BODY>
<?php
\$ip_server = \$_SERVER['SERVER_ADDR'];
echo "Hello from \$ip_server - Instance 1";
?>
</BODY>
EOF

sudo chmod 744 $WEBDIR1/*.{html,php} 2>/dev/null

cat >"$WEBDIR2/index.php" <<EOF
<HTML>
<HEAD>
    <TITLE>Hello from Instance 2</TITLE>
</HEAD>
<BODY>
<?php
\$ip_server = \$_SERVER['SERVER_ADDR'];
echo "Hello from \$ip_server - Instance 2";
?>
</BODY>
EOF

sudo chmod 744 $WEBDIR2/*.{html,php} 2>/dev/null

# start the container
docker run \
  --hostname "$CNAME1" \
  --publish "8081:80" \
  --volume "$WEBDIR1:/var/www/html" \
  --name "$CNAME1" \
  --detach \
  php:apache

# start the second container
docker run \
  --hostname "$CNAME2" \
  --publish "8082:80" \
  --volume "$WEBDIR2:/var/www/html" \
  --name "$CNAME2" \
  --detach \
  php:apache