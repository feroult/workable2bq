import json
import os
import time
import hashlib
import sys
from workable_api import get

LIMIT = 3000


def load_collection(start_path, key, fn, context={}):
    with open(f'/export_views/{key}.json', 'a+') as writer:
        path = start_path
        while True:
            print(path)
            j = get(path).json()
            if key in j:
                for el in j[key]:
                    o = fn(el, context)
                    writer.write(json.dumps(o))
                    writer.write('\n')
            else:
                print(j)
                time.sleep(2)
                continue
            if 'paging' in j:
                uri = j['paging']['next']
                path = uri[uri.index('/v3/')+4:]
                time.sleep(0.5)
            else:
                break


def load_activity(activity, context):
    # if 'candidate' in activity:
    #     activity['candidate']['name'] = hashlib.sha1(
    #         activity['candidate']['name'].encode('utf-8')).hexdigest()
    # if 'member' in activity:
    #     activity['member']['name'] = hashlib.sha1(
    #         activity['member']['name'].encode('utf-8')).hexdigest()
    # activity['body'] = ''
    activity['job_shortcode'] = context['job_shortcode']
    return activity


def load_candidate(candidate, context):
    return candidate


def load_job(job, context):
    shortcode = job['shortcode']
    context['job_shortcode'] = shortcode
    if 'department' in job and job['department'] == 'DEXTRA':
        load_collection(f'jobs/{shortcode}/activities?limit={LIMIT}',
                        'activities',
                        load_activity)
    return job


def load_jobs():
    # f'jobs?state=published&limit=1000'
    load_collection(f'jobs?limit={LIMIT}',
                    'jobs',
                    load_job)


def load_candidates():
    load_collection(f'candidates?limit={LIMIT}',
                    'candidates',
                    load_candidate)


if __name__ == '__main__':
    load_candidates()
    load_jobs()
