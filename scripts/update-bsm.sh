#!/bin/bash

cd /opt/barry-service-manager

git fetch

git reset --hard origin/master

servicectl restart barry-service-manager