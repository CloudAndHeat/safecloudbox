#!/usr/bin/env python3

import boto3, os, docopt, datetime
from botocore.client import Config


__doc__ = """
Run the equivalent of "s3cmd <command>". Use AWS_ACCESS_KEY, AWS_SECRET_KEY and
AWS_S3_URL env vars. Only very limited functionality supported.

usage:
    ./{this} ( ls [-v] [-o] | mb [<bucket>] [-o] | rb <buckets>... |
               put <bucket> <file> [<object>] | get <bucket> <object> [<file>] )

options:
    -v  verbose
    -o  list (ls) / create (mb) objects in buckets

commands:
    mb   make bucket (with random name if <bucket> is omitted), add one object
         when used with -o (e.g. "upload a file")
    rb   remove bucket recursively
    ls   list buckets, list objects with -o
    put  upload <file> to <bucket>, optionally name it <object> (default is the
         file's basename), bucket is created if needed
    get  download <object> from <bucket>, optionally and name it <file>

examples:
    Delete all buckets.
    $ ./{this} ls | xargs ./{this} rb
""".format(this=os.path.basename(__file__))


def timestamp():
    """UTC timestamp with microseconds (1e-6 s) resolution.

    We use float seconds as per ISO 8601/RFC 3339, e.g.
    2018-08-06T13:30:55.123456Z where 55.123456 are 55 seconds + 123456
    microseconds.

    >>> time.time()
    1533567100.2931738
    >>> datetime.datetime.utcfromtimestamp(1533567100.2931738)
    datetime.datetime(2018, 8, 6, 14, 51, 40, 293174)
    >>> datetime.datetime.utcfromtimestamp(1533567100.2931738).strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    '2018-08-06T14:51:40.293174Z'
    """
    return datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%fZ')


def bucketname():
    """Timestamp-based bucket name.

    AWS has strict bucket naming rules (e.g. lowercase) since bucket names are
    global (as in all over the world). Stupid. Namespaces anyone??
    https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
    """
    return timestamp().replace(':' , '-').lower()


def list_buckets(conn, content=False, verbose=False):
    """List all buckets (and each object in them if `content=True`) from a Boto
    S3 connection. Equivalent of "s3cmd ls | la".

    Parameters
    ----------
    conn : result of ``boto.resource('s3', ...)``
    content : bool
        list content of bucket
    """
    for bucket in conn.buckets.all():
        if verbose:
            print("bucket={name} created={created}".format(
                  name=bucket.name,
                  created=bucket.creation_date))
        else:
            print(bucket.name)
        if content:
            for obj in bucket.objects.all():
                if verbose:
                    print("    object={name} size={size} modified={modified}".format(
                          name=obj.key,
                          size=obj.size,
                          modified=obj.last_modified,
                          ))
                else:
                    print("    " + obj.key)


def remove_bucket(conn, bucket_name):
    """
    Parameters
    ----------
    conn : result of ``boto.resource('s3', ...)``
    bucket_name : str
        bucket name, e.g. 'foo' if the full bucket name is
        's3://foo'
    """
    bucket = conn.Bucket(bucket_name)
    print("delete: bucket={}".format(bucket_name))
    for obj in bucket.objects.all():
        print("    delete: object={}".format(obj.key))
        obj.delete()
    bucket.delete()


def make_bucket(conn, bucket_name=None, content=False):
    """
    Parameters
    ----------
    conn : result of ``boto.resource('s3', ...)``
    bucket_name : str
        bucket name, e.g. 'foo' if the full bucket name is
        's3://foo'
    """
    # Can only create lower case bucket names, else
    #     boto.exception.BotoClientError: BotoClientError: Bucket names cannot
    #     contain upper-case characters when using either the sub-domain or
    #     virtual hosting calling format.
    if bucket_name is None:
        _name = '{}-{}'.format('boto-test-bucket', bucketname())
    else:
        _name = bucket_name.lower()
    print("creating bucket: {}".format(_name))
    conn.create_bucket(Bucket=_name)
    if content:
        conn.Object(_name, 'foo').put(Body='bar')


def put_file(conn, file_name, bucket_name, object_name=None):
    # need to check for a faster, maybe boto built-in method to check for
    # existing buckets
    if not bucket_name in [x.name for x in conn.buckets.all()]:
        make_bucket(conn, bucket_name=bucket_name, content=False)
    if object_name is None:
        object_name = os.path.basename(file_name)
    with open(file_name, 'rb') as fd:
        conn.Object(bucket_name, object_name).put(Body=fd)


def get_file(conn, bucket_name, object_name, file_name=None):
    if file_name is None:
        file_name = object_name
    conn.Bucket(bucket_name).download_file(object_name, file_name)


if __name__ == '__main__':

    args = docopt.docopt(__doc__)

    # signature_version=s3
    #   Old signature. Some AWS regions (Frankfurt?) support only the newer one
    #   's3v4' -- version 4 signatures, which perform incomprehensible URL name
    #   munging and signing.
    # addressing_style='path'
    #   AFAIK, this is the boto3 equivalent of boto2's
    #       conn = boto.connect_s3(
    #           calling_format=boto.s3.connection.OrdinaryCallingFormat(),
    #           )
    #   which we needed to use against Ceph's S3 API. With boto3, we don't need
    #   that. Also the region name is not used. However, both are somehow
    #   needed when using s3v4 as far as we could find out. Boto3's and AWS's
    #   documentation is convoluted.
    conn = boto3.resource(
        's3',
        aws_access_key_id=os.environ['S3_ACCESS_KEY'],
        aws_secret_access_key=os.environ['S3_SECRET_KEY'],
        endpoint_url=os.environ['S3_URL'],
##        config=Config(signature_version='s3', # or s3v4
##                      s3=dict(addressing_style='path'),
##                      region_name='ceph'),
        config=Config(signature_version='s3')
        )

    if args['mb']:
        make_bucket(conn, content=args['-o'], bucket_name=args['<bucket>'])
    elif args['rb']:
        for bucket_name in args['<buckets>']:
            remove_bucket(conn, bucket_name)
    elif args['ls']:
        list_buckets(conn, content=args['-o'], verbose=args['-v'])
    elif args['put']:
        put_file(conn, 
                 bucket_name=args['<bucket>'], 
                 file_name=args['<file>'], 
                 object_name=args['<object>'])
    elif args['get']:
        get_file(conn, 
                 bucket_name=args['<bucket>'], 
                 file_name=args['<file>'], 
                 object_name=args['<object>'])
