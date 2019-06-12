#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
    echo "Required arguments [BUCKETNAME] not provided!"
    exit 1
fi

LOCALIP=`/opt/aws/bin/ec2-metadata -o|cut -d' ' -f2`

BUCKETNAME=$1

echo "enable for docker service"
chkconfig --add docker
echo "start docker service"
service docker start

curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

if [ $BUCKETNAME != "skip" ]; then
   /opt/aws/bin/ec2-metadata -o | cut -d' ' -f2 > /root/webserver.ip
   /usr/bin/aws s3 cp /root/webserver.ip s3://$BUCKETNAME/
fi

KAFKA_LISTENER=PLAINTEXT://$LOCALIP:9092 docker-compose up -d
