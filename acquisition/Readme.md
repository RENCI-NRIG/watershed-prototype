# Data Acquisition
Uses kafka(zoo keeper) along with a python client to push measurements read from the CSV file to Elastic Search Database.
# Kafa
Kafa is running in a docker container (defined in docker-compose.yml). Kafka pushes the data to logstash on Elastic Server.

# Python Client
Watershed python client is based on python3, parses the input csv file and uses kafka-python to push the data to kafka which in turn sends it to Elastic Database.

# Usage

```
# python3 watershed_client.py -h
usage: watershed_client.py [-h] -f FILE

Python client to provision cloud resources by invoking Mobius REST Commands.

optional arguments:
  -h, --help            show this help message and exit
  -f FILE, --file FILE  CSV file containing the time series measurement data
                        for a specific location
```
