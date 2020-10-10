import os
import sys
import requests

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
            continue
