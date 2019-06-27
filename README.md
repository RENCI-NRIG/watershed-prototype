# watershed-prototype
Prototype of a data-acquisition system for the watershed project

This project involves development and configuration of cloud-based data collection, analysis and visualization pipeline as well as kafka bases acquistion system. 

## Analysis & Visualization Pipeline
Analysis and visualization pipeline is implemented via Elastic Search, Logstash and Kibana stack.

## Acquisition
Using python client to inject the data via a CSV file which is pushed to Kafka. Kafka is connected to logstash and in turn pushes the data to Elastic Database
