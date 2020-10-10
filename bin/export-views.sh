#!/bin/bash

python3.7 /app/export_views.py
./bq-load-views.sh