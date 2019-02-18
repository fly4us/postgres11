#!/bin/bash
 
env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass repmgrd -f /etc/repmgr.conf -v
