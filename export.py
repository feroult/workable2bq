import requests
import json
import os
import time


WORKABLE_TOKEN = os.environ['WORKABLE_TOKEN']
WORKABLE_DOMAIN = os.environ['WORKABLE_DOMAIN']

WORKABLE_API = f'https://{WORKABLE_DOMAIN}.workable.com/spi/v3'


def get(path, params={}):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {WORKABLE_TOKEN}'
    }
    return requests.get(f'{WORKABLE_API}/{path}', headers=headers, params=params)


def load_collection(start_path, key, fn):
    with open(f'/exports/{key}.json', 'a+') as writer:
        path = start_path
        while True:
            print(path)
            j = get(path).json()
            if key in j:
                for el in j[key]:
                    writer.write(json.dumps(el))
                    writer.write('\n')
                    fn(el)
            else:
                print(j)
            if 'paging' in j:
                path = j['paging']['next'][len(WORKABLE_API)+1:]
                time.sleep(0.5)
            else:
                break


def load_activity(activity):
    pass


def load_candidate(activity):
    pass


def load_job(job):
    shortcode = job['shortcode']
    load_collection(f'jobs/{shortcode}/activities?limit=1000',
                    'activities',
                    load_activity)


def load_jobs():
    load_collection(f'jobs?state=published&limit=1000',
                    'jobs',
                    load_job)


def load_candidates():
    load_collection(f'candidates?limit=1000',
                    'candidates',
                    load_candidate)


if __name__ == '__main__':
    # load_jobs()
    load_candidates()
