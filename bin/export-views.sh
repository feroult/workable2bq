#!/bin/bash

python3.7 /app/export_views.py
/app/bin//bq-load-views.sh