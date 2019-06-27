#
# Copyright (c) 2017 Renaissance Computing Institute, except where noted.
# All rights reserved.
#
# This software is released under GPLv2
#
# Renaissance Computing Institute,
# (A Joint Institute between the University of North Carolina at Chapel Hill,
# North Carolina State University, and Duke University)
# http://www.renci.org
#
# For questions, comments please contact software@renci.org
#
# Author: Komal Thareja(kthare10@renci.org)
import sys
import os
import time
import json
import argparse
import subprocess
import csv

from kafka import KafkaProducer

def publish_message(producer_instance, topic_name, value):
    try:
        value_bytes = bytes(value, encoding='utf-8')
        producer_instance.send(topic_name, value=value_bytes)
        producer_instance.flush()
        print('Message published successfully.')
    except Exception as ex:
        print('Exception in publishing message' + str(ex))


def connect_kafka_producer():
    producer = None
    try:
        producer = KafkaProducer(bootstrap_servers=[os.getenv('KAFKA_HOST', 'localhost:9092')], api_version=(0, 10))
    except Exception as ex:
        print('Exception while connecting Kafka')
        print(str(ex))
    finally:
        return producer


def main():
    parser = argparse.ArgumentParser(description='Python client to provision cloud resources by invoking Mobius REST Commands.\n')

    parser.add_argument('-f',
                        '--file',
                        dest='file',
                        type = str,
                        help='CSV file containing the time series measurement data for a specific location',
                        required=True
    )

    args = parser.parse_args()
    lat = None
    lon = None
    siteCode = None
    d = {}
    d['DateTime'] = []
    d['TimeOffset'] = []
    d['DateTimeUTC'] = []
    d['MaxBotix_MB7386_Distance'] = []
    d['Maxim_DS3231_Temp'] = []
    d['EnviroDIY_Mayfly_Batt'] = []
    d['EnviroDIY_Mayfly_FreeRAM'] = []
    d['Sodaq_Cellular_RSSI'] = []
    d['Sodaq_Cellular_SignalPercent'] = []
    d['Atlas_Conductivity'] = []
    d['Atlas_DOconc'] = []
    d['Atlas_Temp'] = []

    fp = open(args.file)
    # use filter(lambda row: row[0]!='#', fp) instead of fp to skip comments
    dictReader = csv.DictReader(fp, fieldnames = ['DateTime', 'TimeOffset', 'DateTimeUTC', 'MaxBotix_MB7386_Distance', 'Maxim_DS3231_Temp', 'EnviroDIY_Mayfly_Batt', 'EnviroDIY_Mayfly_FreeRAM', 'Sodaq_Cellular_RSSI', 'Sodaq_Cellular_SignalPercent', 'Atlas_Conductivity', 'Atlas_DOconc', 'Atlas_Temp'], delimiter = ',')


    for row in dictReader:
        if '#' in str(row['DateTime']) :
            if 'Latitude' in str(row['DateTime']) :
                lat = str(row['DateTime']).split(':')[1].strip()
            if 'Longitude' in str(row['DateTime']) : 
                lon = str(row['DateTime']).split(':')[1].strip()
            if 'SiteCode' in str(row['DateTime']) : 
                siteCode = str(row['DateTime']).split(':')[1].strip()
        else:
            if 'DateTime' not in str(row['DateTime']) :
                for key in row:
                    d[key].append(row[key])
    fp.close()

    print ("Read " + str(len(d['DateTime'])) + " measurements for siteCode: " + siteCode + " lat: " + lat + " lon: " + lon)

    producer = connect_kafka_producer()


    for i in range(len(d['DateTime'])):
        dataToPush = siteCode + " " + lat + " " + lon + " " + str(d['DateTime'][i]) + " " + str(d['DateTimeUTC'][i]) + " "
        #dataToPush = siteCode + " " + lat + " " + lon + " " + str(d['DateTime'][i]) + " " + str(d['TimeOffset'][i]) + " " + str(d['DateTimeUTC'][i]) + " "

        if str(d['MaxBotix_MB7386_Distance'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['MaxBotix_MB7386_Distance'][i])
            dataToPush += " "

        if str(d['Maxim_DS3231_Temp'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['Maxim_DS3231_Temp'][i])
            dataToPush += " "

        if str(d['EnviroDIY_Mayfly_Batt'][i])  == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['EnviroDIY_Mayfly_Batt'][i])
            dataToPush += " "

        if str(d['EnviroDIY_Mayfly_FreeRAM'][i])   == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['EnviroDIY_Mayfly_FreeRAM'][i])
            dataToPush += " "

        if str(d['Sodaq_Cellular_RSSI'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['Sodaq_Cellular_RSSI'][i])
            dataToPush += " "

        if str(d['Sodaq_Cellular_SignalPercent'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['Sodaq_Cellular_SignalPercent'][i])
            dataToPush += " "

        if str(d['Atlas_Conductivity'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['Atlas_Conductivity'][i])
            dataToPush += " "

        if str(d['Atlas_DOconc'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['Atlas_DOconc'][i])
            dataToPush += " "

        if str(d['Atlas_Temp'][i]) == "" :
            dataToPush += "-1 "
        else :
            dataToPush += str(d['Atlas_Temp'][i])

        print (dataToPush)
        publish_message(producer, 'pft', dataToPush)
        

    sys.exit(0)

if __name__ == '__main__':
    main()
