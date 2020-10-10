import os
import requests

from google.cloud import bigquery
from google.cloud import storage

bigquery_client = bigquery.Client()
storage_client = storage.Client()

BUCKET_NAME = os.environ['BUCKET_NAME']
DEFAULT_CURSOR = '2020-01-01'
LIMIT = 10

WORKABLE_TOKEN = os.environ['WORKABLE_TOKEN']
WORKABLE_DOMAIN = os.environ['WORKABLE_DOMAIN']

WORKABLE_API = f'https://{WORKABLE_DOMAIN}.workable.com/spi/v3'


def get(path, params={}):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {WORKABLE_TOKEN}'
    }
    while True:
        try:
            return requests.get(f'{WORKABLE_API}/{path}', headers=headers, params=params)
        except KeyboardInterrupt:
            sys.exit()
        except BaseException as e:
            print(e)
            sys.exit()


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
        load_tags(row['id'])
        batch_count = batch_count + 1
        if batch_count == SAVE_CURSOR_COUNT:
            save_cursor(row['updated_at'])


def load_tags(id):
    print(f'loading {id}')
    j = get(f'candidates/{id}').json()
    print(j)


def save_cursor(cursor):
    upload_string('tags/cursor', cursor)


def load_cursor():
    try:
        return download_string('tags/cursor')
    except:
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
