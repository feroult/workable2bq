#!/bin/bash

python3.7 /app/export_candidates.py
./bq-load-candidates.sh