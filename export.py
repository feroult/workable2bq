import requests
import json
import os


WORKABLE_TOKEN = os.environ['WORKABLE_TOKEN']
WORKABLE_DOMAIN = os.environ['WORKABLE_DOMAIN']

WORKABLE_API = f'https://{WORKABLE_DOMAIN}.workable.com/spi/v3'

def get(path, params={}):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {WORKABLE_TOKEN}'
    }
    return requests.get(f'{WORKABLE_API}/{path}', headers=headers, params=params)

def load_job(shortcode):
    print(shortcode)
    # r = get(f'jobs/{shortcode}/activities')
    # print(json.dumps(r.json(), indent=1))

def load_jobs():
    r = get('jobs', {'state': 'published'})
    jobs = r.json()['jobs']
    
    for job in jobs:
        shortcode = job['shortcode']
        load_job(shortcode)
        # print(json.dumps(job))
        # print(json.dumps(r.json(), indent=1))
        
if __name__ == '__main__':
    load_jobs()
