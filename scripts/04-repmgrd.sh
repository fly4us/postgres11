#!/bin/bash
 
env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass repmgrd -f ${PGDATA}/repmgr.conf -v
