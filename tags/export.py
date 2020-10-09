from google.cloud import bigquery
from google.cloud import storage

bigquery_client = bigquery.Client()
storage_client = storage.Client()


def load_tags():
    query = """
        SELECT * 
        FROM workable.candidates 
        ORDER BY updated_at DESC LIMIT 100
    """
    query_job = bigquery_client.query(query)

    first_row = None
    last_row = None

    for row in query_job:
        if not first_row:
            first_row = row

        # Row values can be accessed by field name or index.
        print("name={}".format(row["name"]))
        last_row = row

    print(first_row['updated_at'])
    print(last_row['updated_at'])


def upload_string(bucket_name, s, destination_blob_name):
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_string(s)


def download_string(bucket_name, source_blob_name):
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(source_blob_name)
    return blob.download_as_string()


if __name__ == '__main__':
    # load_tags()
    upload_string('workable2bq-raw', 'xpto', 'tags/created_at_first')
    x = download_string('workable2bq-raw', 'tags/created_at_first')
    print(f"x={x}")
