#!/bin/bash
 
env -u PGPASSWORD repmgrd -f /etc/postgresql/11/main/repmgr.conf -v
