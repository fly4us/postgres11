#!/bin/bash
 
env -u PGPASSWORD PGPASSFILE=/etc/postgresql/11/main/.pgpass repmgrd -f /etc/postgresql/11/main/repmgr.conf -v
