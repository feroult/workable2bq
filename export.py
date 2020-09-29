import requests
import json
import os

WORKABLE_API = 'https://dextra.workable.com/spi/v3'
WORKABLE_TOKEN = os.environ['WORKABLE_TOKEN'])

def get(path, params={}):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {WORKABLE_TOKEN}'
    }
    return requests.get(f'{WORKABLE_API}/{path}', headers=headers, params=params)


def load_jobs():
    r = get('jobs', {'state': 'published'})
    jobs = r.json()['jobs']
    
    for job in jobs:
        shortcode = job['shortcode']
        print(shortcode)
        # print(json.dumps(job))
        # print(json.dumps(r.json(), indent=1))
        


if __name__ == '__main__':
    load_jobs()
