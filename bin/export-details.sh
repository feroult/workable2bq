#!/bin/bash

python3.7 /app/export_details.py
./bq-load-details.sh