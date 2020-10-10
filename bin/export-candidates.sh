#!/bin/bash

python3.7 /app/export_candidates.py
/app/bin/bq-load-candidates.sh