#!/bin/bash

python3.7 /app/export_tags.py
./bq-load-tags.sh