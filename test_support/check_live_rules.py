"""Check published Firestore rules with client credentials; remove all test data."""
import copy
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
config = json.loads((ROOT / 'android/app/google-services.json').read_text())
key = config['client'][0]['api_key'][0]['current_key']
project = config['project_info']['project_id']
local = '--emulator' in sys.argv
firestore_host = 'http://127.0.0.1:8085' if local else 'https://firestore.googleapis.com'
auth_host = 'http://127.0.0.1:9095/identitytoolkit.googleapis.com' if local else 'https://identitytoolkit.googleapis.com'
base = f'{firestore_host}/v1/projects/{project}/databases/(default)/documents/books'
password = os.environ['BOOKSHELF_TEST_PASSWORD']
results = []
created = []

def request(url, method='GET', data=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(url, method=method, headers=headers,
        data=None if data is None else json.dumps(data).encode())
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, json.load(error)

def auth(action, email=None, token=None):
    data = {'idToken': token} if token else {'email': email, 'password': password, 'returnSecureToken': True}
    status, value = request(f'{auth_host}/v1/accounts:{action}?key={key}', 'POST', data)
    assert status == 200, (action, status, value.get('error', {}).get('message'))
    return value

def check(name, passed):
    assert passed, name
    results.append({'check': name, 'passed': True})
    print('PASS', name, flush=True)

def part(value):
    return value.strip().lower().replace('%', '%25').replace('/', '%2F').replace('_', '%5F')

def fields(values):
    out = {}
    for k, v in values.items():
        if k == 'createdAt': out[k] = {'timestampValue': v}
        elif isinstance(v, bool): out[k] = {'booleanValue': v}
        elif isinstance(v, int): out[k] = {'integerValue': str(v)}
        elif isinstance(v, float): out[k] = {'doubleValue': v}
        else: out[k] = {'stringValue': v}
    return {'fields': out}

primary = auth('signUp' if local else 'signInWithPassword', 'grader.qe200012@example.com')
token, uid = primary['idToken'], primary['localId']
stamp = str(int(time.time()))
sample = {'userId': uid, 'title': 'Audit ' + stamp, 'author': 'Rules Check',
    'genre': 'Fiction', 'status': 'To Read', 'favorite': False,
    'createdAt': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')}
other = None

def write(values, *, owner_token=token, forced_id=None, method='PATCH'):
    values = copy.deepcopy(values)
    doc_id = forced_id or f"{values['userId']}__{part(values['title'])}__{part(values['author'])}"
    values['id'] = doc_id
    url = base + '/' + urllib.parse.quote(doc_id, safe='')
    if method == 'POST':
        url = base + '?documentId=' + urllib.parse.quote(doc_id, safe='')
    status, body = request(url, method, fields(values), owner_token)
    if status == 200:
        created.append((doc_id, owner_token))
    return status, body, doc_id

try:
    for name, change in [
        ('empty title', {'title': ''}), ('spaces title', {'title': '   '}),
        ('title 101 chars', {'title': 'T' * 101}),
        ('empty author', {'author': ''}), ('spaces author', {'author': '   '}),
        ('author 61 chars', {'author': 'A' * 61}),
        ('unknown genre', {'genre': 'Wrong'}), ('unknown status', {'status': 'Wrong'}),
        ('rating below zero', {'rating': -1}), ('rating above five', {'rating': 6}),
        ('fractional rating', {'rating': 1.5}), ('text rating', {'rating': '5'}),
        ('notes 301 chars', {'notes': 'N' * 301}), ('forged owner', {'userId': 'not-the-owner'}),
    ]:
        status, _, _ = write({**sample, **change})
        check(name + ' refused', status == 403)
    for missing in ['title', 'author', 'genre', 'status', 'favorite', 'userId', 'createdAt']:
        data = fields({**sample, 'id': uid + '__missing_' + missing})
        del data['fields'][missing]
        status, _ = request(base + '/' + uid + '__missing_' + missing, 'PATCH', data, token)
        check('missing ' + missing + ' refused', status == 403)
    status, _, doc_id = write(sample, method='POST')
    check('valid book without rating or notes accepted', status == 200)
    status, _, _ = write({**sample, 'title': sample['title'].upper()}, method='POST')
    check('case duplicate cannot be created twice', status in (403, 409))
    status, _, _ = write(sample, forced_id=uid + '__forged_duplicate_' + stamp)
    check('duplicate under a different document ID refused', status == 403)
    for rating in (0, 5):
        values = {**sample, 'title': ('T' * 99) + str(rating), 'author': 'A' * 60,
            'notes': 'N' * 300, 'rating': rating}
        status, _, _ = write(values, method='POST')
        check(f'valid length boundaries and rating {rating} accepted', status == 200)
    url = base + '/' + urllib.parse.quote(doc_id, safe='')
    status, _ = request(url)
    check('visitor read refused', status == 403)
    status, _ = request(url, 'PATCH', fields({**sample, 'id': doc_id}))
    check('visitor write refused', status == 403)
    other = auth('signUp', f'audit.qe190064.{stamp}@example.com')
    other_token = other['idToken']
    for method in ('GET', 'PATCH', 'DELETE'):
        status, _ = request(url, method, fields({**sample, 'id': doc_id}) if method == 'PATCH' else None, other_token)
        check('another account ' + method + ' refused', status == 403)
    status, _, _ = write({**sample, 'userId': other['localId']}, owner_token=other_token, method='POST')
    check('different users may save the same title and author', status == 200)
finally:
    for doc_id, owner_token in dict.fromkeys(created):
        status, _ = request(base + '/' + urllib.parse.quote(doc_id, safe=''), 'DELETE', token=owner_token)
        if status not in (200, 404):
            raise RuntimeError('Test document cleanup failed: ' + str(status))
    if other:
        auth('delete', token=other['idToken'])
    output = 'emulator-rules-results.json' if local else 'live-rules-results.json'
    (ROOT / output).write_text(json.dumps(results, indent=2))
    print('Temporary test documents and account cleaned up.', flush=True)
