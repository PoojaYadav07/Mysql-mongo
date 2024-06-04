#!/bin/bash

DB_TYPE=$1
MYSQL_USER="localhost"
MYSQL_PASSWORD="password"
MYSQL_DB="mysql_database"
MYSQL_TABLE="tasks"
MONGO_DB="mongo_database"
MONGO_COLLECTION="tasks"
SUCCESS_TRACK_FILE="success_track_file.txt"
FAILURE_TRACK_FILE="failure_track_file.txt"

process_mysql() {

    shopt -s nocasematch

    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$MYSQL_DB" -sN -e "SELECT id, name, status, meta_data FROM $MYSQL_TABLE" | while read -r id name status meta_data
    do
        current_time=$(date "+%Y-%m-%d %H:%M:%S")
        if [[ "$status" == "true" ]]; then
            echo "ID: $id, Name: $name, Status: true, Meta Data: $meta_data, Timestamp: $current_time" >> "$SUCCESS_TRACK_FILE"
        else
            echo "ID: $id, Name: $name, Status: false, Meta Data: $meta_data, Timestamp: $current_time" >> "$FAILURE_TRACK_FILE"
        fi
    done

    shopt -u nocasematch
}

process_mongo() {
    mongo --quiet --eval "db.getSiblingDB('$MONGO_DB').$MONGO_COLLECTION.find().forEach(printjson)" | while read -r doc
    do
        id=$(echo $doc | jq -r '._id.$oid')
        name=$(echo $doc | jq -r '.name')
        status=$(echo $doc | jq -r '.status')
        meta_data=$(echo $doc | jq -r '.meta_data')
        current_time=$(date "+%Y-%m-%d %H:%M:%S")
        if [ "$status" == "true" ]; then
            echo "ID: $id, Name: $name, Status: TRUE, Meta Data: $meta_data, Timestamp: $current_time" >> $SUCCESS_TRACK_FILE
        else
            echo "ID: $id, Name: $name, Status: FALSE, Meta Data: $meta_data, Timestamp: $current_time" >> $FAILURE_TRACK_FILE
        fi
    done
}

if [ "$DB_TYPE" == "mysql" ]; then
    process_mysql
elif [ "$DB_TYPE" == "mongo" ]; then
    process_mongo
else
    echo "Invalid database type. Please specify 'mysql' or 'mongo'."
fi
