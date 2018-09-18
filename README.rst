About
-----
The SafeCloudBox private cloud solution demonstrator, developed by
https://www.cloudandheat.com/ within the SafeCloud project
(https://www.safecloud-project.eu).

Install
-------
To run the startup script, you need docker_, docker-compose_ and some Python
packages. On Debian-ish systems::

    $ apt-get install python3-docopt python3-boto3

else::

    $ pip3 install boto3 docopt

Run
---

We start safecloudbox on one host. We run two Docker containers: (i) a
coordination service container (1-replica DepSpace, using DepSpacito_), (ii) a
SafeCloudFS_ container using 4 S3 buckets behind a single S3 endpoint. We use
``docker-compose`` to start the DepSpace and SafeCloudFS containers.
``docker-compose`` will build the container images if none are present.

To start, you need to export your S3 credentials and then run ``start.sh``.

::

    $ export S3_URL=https://object-store-f1a.cloudandheat.com:8080 \
             S3_ACCESS_KEY=12345678 \
             S3_SECRET_KEY=pazzzw0rd11!!11
    $ ./start.sh

After both containers are up and all services are running, point your browser
to port 80 and login to Nextcloud using random passwords (generated newly at
container start).

    =====   ===================
    login   password
    -----   -------------------
    admin   /tmp/scb/admin_pass
    user    /tmp/scb/user_pass
    =====   ===================

Cleanup::

    $ ./stop.sh

Run SafeCloudFS tests
---------------------

Enter the SafeCloudFS container and execute the test script::

    $ docker exec -ti safecloudfs bash
    root@safecloudfs# /tmp/scb/test-safecloudfs.sh /mnt/safecloudfs

Ceph S3 @ C&H OpenStack
-----------------------

First, register an account at https://www.cloudandheat.com. You will receive
login credentials and ``ssh`` access to our datacenters. Then, create S3
credentials (``S3_ACCESS_KEY``, ``S3_SECRET_KEY``) for the Ceph backends.
``ssh`` to one datacenter, e.g. ``f1a``

::

    ssh your.name@dashboard-f1a.cloudandheat.com

and then run the command::

    $ openstack ec2 credentials create

How it works
------------
SafeCloudFS is a tool which encrypts and stores your data in a fault-tolerant
way. We connect that to Nextcloud_: Data you save in Nextcloud gets written to
``/var/www/html/``, which is a local cache (Docker volume). We sync files from
there to SafeCloudFS, which in turn saves the data to S3 backends in C&H's
infrastructure.


Build Docker images
-------------------

For local debugging, it may be useful to build the images before running
``docker-compose``. In that case, ``docker-compose`` will use those instead of
building them.

::

    $ git clone https://github.com/CloudAndHeat/SafeCloudFS
    $ cd SafeCloudFS && git checkout feature-safecloudbox \
        && docker build -t safecloudfs:feature-safecloudbox . && cd ..
    $ git clone https://github.com/inesc-id/DepSpacito
    $ cd DepSpacito && docker build -t depspacito . && cd ..



.. _docker: https://docs.docker.com/install
.. _docker-compose: https://docs.docker.com/compose/install
.. _DepSpacito: https://github.com/inesc-id/DepSpacito
.. _SafeCloudFS: https://github.com/CloudAndHeat/SafeCloudFS
.. _Nextcloud: https://nextcloud.com/
