import os
import json
import time
from workable_api import get

from google.cloud import bigquery
from google.cloud import storage

bigquery_client = bigquery.Client()
storage_client = storage.Client()

BUCKET_NAME = os.environ['BUCKET_NAME']
DEFAULT_CURSOR = '2020-01-01'
LIMIT = 2000

SAVE_CURSOR_COUNT = 100


def load_candidates():
    query = f"""
        SELECT DISTINCT c.id, updated_at FROM workable.candidates c
          LEFT JOIN workable.jobs j ON c.job.shortcode = j.shortcode
         WHERE j.department = 'DEXTRA'
           AND c.updated_at >= TIMESTAMP '{load_cursor()}'
        ORDER BY updated_at
        LIMIT {LIMIT}
    """
    query_job = bigquery_client.query(query)

    batch_count = 0

    for row in query_job:
        load_candidate(row['id'])
        batch_count = batch_count + 1
        if batch_count % SAVE_CURSOR_COUNT == 0:
            save_cursor(row['updated_at'])

    if row:
        save_cursor(row['updated_at'])


def load_candidate(id):
    with open(f'/export_candidates/{id}.json', 'w') as writer:
        print(f'Loading {id}')
        while True:
            j = get(f'candidates/{id}').json()
            if 'candidate' not in j:
                print(j)
                time.sleep(2)
                continue
            o = j['candidate']
            s = json.dumps(o)
            writer.write(s)
            upload_string(s, f'candidates/{id}.json')
            time.sleep(0.2)
            break


def save_cursor(cursor):
    s = cursor.strftime("%Y-%m-%d %H:%M:%S")
    print(f'Saving cursor {s}')
    upload_string(s, 'cursor/candidates')


def load_cursor():
    try:
        cursor = download_string('cursor/candidates').decode("utf-8")
        print(f'Loading from cursor {cursor}')
        return cursor
    except:
        print(f'Loading default cursor {DEFAULT_CURSOR}')
        return DEFAULT_CURSOR


def upload_string(s, destination_blob_name):
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_string(s)


def download_string(source_blob_name):
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(source_blob_name)
    return blob.download_as_string()


if __name__ == '__main__':
    load_candidates()
