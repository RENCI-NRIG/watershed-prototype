#!/usr/bin/env bash
set -e

if [ $# -ne 2 ]; then
    echo "Required arguments [BUCKETNAME] [ELASTIC_VERSION] not provided"
    exit 1
fi

BUCKETNAME=$1
ELASTIC_VERSION=$2
ES_PASSWORD=elastic
DEFAULT_INDEX_PATTERN=logstash
LOCALIP=`/opt/aws/bin/ec2-metadata -o|cut -d' ' -f2`

echo "Installing java"
/usr/bin/yum -y install java-1.8.0-openjdk
JAVA_VERSION=`java -version 2>&1 | awk -F '"' '/version/ {print $2}'| cut -d'_' -f1`
echo "Java version installed: $JAVA_VERSION"
if [ "$JAVA_VERSION" != "1.8.0" ]; then
   echo \"Removing $JAVA_VERSION\"
   java_rpm_to_be_removed=`rpm -qa | grep openjdk-"$JAVA_VERSION"`
   rpm -e "$java_rpm_to_be_removed"
fi

#Install elastic
echo "Installing elasticsearch"
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ELASTIC_VERSION.rpm > /dev/null 2>&1
rpm --install elasticsearch-$ELASTIC_VERSION.rpm  > /dev/null 2>&1
chkconfig --add elasticsearch

#Install kibana
echo "Installing kibana"
wget https://artifacts.elastic.co/downloads/kibana/kibana-$ELASTIC_VERSION-x86_64.rpm > /dev/null 2>&1
rpm --install kibana-$ELASTIC_VERSION-x86_64.rpm > /dev/null 2>&1
chkconfig --add kibana

#Install logstash
echo "Installing logstash"
wget https://artifacts.elastic.co/downloads/logstash/logstash-$ELASTIC_VERSION.rpm > /dev/null 2>&1
rpm --install logstash-$ELASTIC_VERSION.rpm > /dev/null 2>&1
initctl start logstash

echo "Setting up config files"
#Install config files
cp /root/lassares/elk/logstash.yml /etc/logstash/logstash.yml
cp /root/lassares/elk/kibana.yml /etc/kibana/kibana.yml
cp /root/lassares/elk/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
cp /root/lassares/elk/logstash-simple.conf /etc/logstash/conf.d/logstash-simple.conf
chmod 644 /etc/logstash/conf.d/logstash-simple.conf

#Change ip address
sed -i 's/172.31.22.51/'$LOCALIP'/g' /etc/logstash/conf.d/logstash-simple.conf
sed -i 's/172.31.22.51/'$LOCALIP'/g' /etc/logstash/logstash.yml
sed -i 's/172.31.22.51/'$LOCALIP'/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/172.31.22.51/'$LOCALIP'/g' /etc/kibana/kibana.yml

chown root:elasticsearch /etc/logstash/conf.d/logstash-simple.conf /etc/logstash/logstash.yml /etc/elasticsearch/elasticsearch.yml /etc/kibana/kibana.yml

rm -rf /root/*.rpm

if [ $BUCKETNAME != "skip" ]; then
   until /usr/bin/aws s3 ls s3://$BUCKETNAME/webserver.ip; do sleep 2; done
   /usr/bin/aws s3 cp s3://$BUCKETNAME/webserver.ip /root/
   /usr/bin/aws s3 rm s3://$BUCKETNAME --recursive
   IP=`cat /root/webserver.ip`
   sed -i 's/172.31.17.173/'$IP'/g' /etc/logstash/conf.d/logstash-simple.conf
fi

echo "Setting boot strap password"
echo changeme  | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin "bootstrap.password"

echo "Restart processes"
service elasticsearch restart
service kibana restart
initctl stop logstash
initctl start logstash

echo "sleeping for 30 seconds"
sleep 30

echo "Setting elastic password to ${ES_PASSWORD}"
curl -s -XPUT -u elastic:changeme "${LOCALIP}:9200/_xpack/security/user/elastic/_password" -H "Content-Type: application/json" -d "{
  \"password\" : \"${ES_PASSWORD}\"
}"

echo "Setting kibana password to ${ES_PASSWORD}"
curl -s -XPUT -u elastic:${ES_PASSWORD} "${LOCALIP}:9200/_xpack/security/user/kibana/_password" -H "Content-Type: application/json" -d "{
  \"password\" : \"${ES_PASSWORD}\"
}"

echo "Setting logstash password to ${ES_PASSWORD}"
curl -s -XPUT -u elastic:${ES_PASSWORD} "${LOCALIP}:9200/_xpack/security/user/logstash_system/_password" -H "Content-Type: application/json" -d "{
  \"password\" : \"${ES_PASSWORD}\"
}"

echo "Begin loading templates"
# Load any declared extra index templates
TEMPLATES=/root/lassares/elk/templates/*.json
for f in $TEMPLATES
do
     filename=$(basename $f)
     template_id="${filename%.*}"
     echo "Loading $template_id template..."
     curl -s  -H 'Content-Type: application/json' -XPUT http://elastic:${ES_PASSWORD}@${LOCALIP}:9200/_template/$template_id \
     -d@$f
done

echo "Begin loading indexes"
INDEX=/root/lassares/elk/index/*.json
for f in $INDEX
do
     filename=$(basename $f)
     index_id="${filename%.*}"
     echo "Loading $index_id index..."
     #We assume we want an index pattern in kibana
     curl -s -X POST http://elastic:${ES_PASSWORD}@${LOCALIP}:5601/api/saved_objects/index-pattern/$index_id \
         -H 'kbn-xsrf:true' -H 'Content-Type: application/json' \
         -d@$f
done

echo "Setup default index"
curl -s -X POST http://elastic:${ES_PASSWORD}@${LOCALIP}:5601/api/kibana/settings/defaultIndex \
     -H 'kbn-xsrf:true' -H 'Content-Type: application/json' \
     -d "{\"value\":\"${DEFAULT_INDEX_PATTERN}\"}"

echo "Setup nodejs and cron job"
wget http://nodejs.org/dist/v9.11.2/node-v9.11.2-linux-x64.tar.gz -O /root/node.tar.gz
tar --strip-components 1 -xzvf /root/node.tar.gz -C /usr/
/usr/bin/npm install elasticsearch

cp -R /root/lassares/elk/cron /root/
#Change ip address
LOCALIP=`/opt/aws/bin/ec2-metadata -o|cut -d' ' -f2`
sed -i 's/172.31.22.51/'$LOCALIP'/g' /root/cron/setupLasaress.js

echo "*/1 * * * * root /usr/bin/node /root/cron/setupLasaress.js > /var/log/setupLasaress.log 2>&1" >> /etc/crontab
service crond restart
## TODO update kafka producer ip in logstash.conf
echo "Configuration complete!"
