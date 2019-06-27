# Elastic Search Kibana Logstash (ELK)

## What is ELK ?
"ELK" is the acronym for three open source projects: Elasticsearch, Logstash, and Kibana. Elasticsearch is a search and analytics engine. Logstash is a server‑side data processing pipeline that ingests data from multiple sources simultaneously, transforms it, and then sends it to a "stash" like Elasticsearch. Kibana lets users visualize data with charts and graphs in Elasticsearch.

The Elastic Stack is the next evolution of the ELK Stack. For more details: [ELK](https://www.elastic.co/elk-stack)

## How to use ?

Clone the code from the watershed-prototype repository on any of linux CentOs-6 based server and execute the configElkServer.sh script
```
# git clone https://github.com/RENCI-NRIG/watershed-prototype.git /root/watershed-prototype
# /root/watershed-prototype/configElkServer.sh <BUCKETNAME> <ELASTIC_VERSION>
```

## What does this installation do?
- Sets up elastic user for elasticsearch, kibana and logstash
- Creates Mapping for the watershed-prototype Measurements
- Creates a Default Index for the watershed-prototype Measurements
