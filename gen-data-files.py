#!/usr/bin/python3

import os, json, textwrap, docopt
from s3tool import bucketname

__doc__ = """
Generate safecloudfs.properties and accounts.json for SafeCloudFS. Use
S3_URL, S3_ACCESS_KEY, S3_SECRET_KEY env vars. Configure 1 or 4 backends,
but using the same S3 credentials, such that in case of 4 backends, we create 4
buckets behind the same endpoint. Use random bucket names.

usage:
    ./{this} <nbackend>
""".format(this=os.path.basename(__file__))


args = docopt.docopt(__doc__)
nbackend = int(args['<nbackend>'])

# these are our use cases, not sure what SafeCloudFS can handle apart from that
assert nbackend in [1,4], "sure you don't want 1 or 4 backends?"

templates = {'safecloudfs.properties': textwrap.dedent("""
    filesystem.protocol={proto}
    upload.method=sync
    clouds.f={clouds_f}
    depspace.config=config
    access.keys.file=config/accounts.json
    cache.dir=cache
    recovery.gui=false
    """).strip()}

safecloudfs_properties = {
    1: dict(proto='DepSky-A', clouds_f=0),            
    4: dict(proto='DepSky-CA', clouds_f=1),            
    }

fn = 'safecloudfs.properties'
prop_txt = templates[fn].format(**safecloudfs_properties[nbackend])

with open(fn, 'w') as fd:
    fd.write(prop_txt)


fn = 'accounts.json'
bucket_prefix = 'safecloudbox-' + bucketname()
accounts = []
for nn in range(nbackend):
    entry = dict(
        provider = 's3',
        identity = os.environ['S3_ACCESS_KEY'],
        credential = os.environ['S3_SECRET_KEY'], 
        containerName = bucket_prefix + '-' + str(nn),
        endpoint = os.environ['S3_URL'],
        )
    accounts.append(entry)

with open(fn, 'w') as fd:
    json.dump(accounts, fd, indent=2)
