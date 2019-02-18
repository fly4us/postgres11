#!/bin/bash
 
set -ex
    
PGHOST=${PRIMARY_NODE}
 
installed=$(env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass psql -qAt -h "$PGHOST" -U "$REPMGR_USER" "$REPMGR_DB" -c "SELECT 1 FROM pg_tables WHERE tablename='nodes'")
 
if [ "${installed}" != "1" ]; then
    echo '~~ 03: registering as primary' >&2
    env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass repmgr -f /etc/repmgr.conf primary register
    exit 0
fi

if [ -n "$WITNESS" ]; then
	echo '~~ 03: registering as witness server' >&2
	env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass repmgr -f /etc/repmgr.conf -h "$PRIMARY_NODE" -U "$REPMGR_USER" -d "$REPMGR_DB" witness register
	exit 0
fi
 
my_node=$(grep node_id ${PGDATA}/repmgr.conf | cut -d= -f 2)
is_reg=$(env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass psql -qAt -h "$PGHOST" -U "$REPMGR_USER" "$REPMGR_DB" -c "SELECT 1 FROM repmgr.nodes WHERE node_id=${my_node}")
 
if [ "${is_reg}" != "1" ] && [ ${my_node} -gt 1 ]; then
    echo '~~ 03: registering as standby' >&2
    pg_ctl -D "$PGDATA" stop -m fast
    rm -Rf "$PGDATA"/*
    env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass repmgr -f /etc/repmgr.conf -h "$PRIMARY_NODE" -U "$REPMGR_USER" -d "$REPMGR_DB" standby clone --fast-checkpoint
    cp /etc/postgresql/11/main/postgresql.conf ${PGDATA}/
    pg_ctl -D "$PGDATA" start &
    sleep 1
    env -u PGPASSWORD PGPASSFILE=${PGDATA}/.pgpass repmgr -f /etc/repmgr.conf -h "$PRIMARY_NODE" -U "$REPMGR_USER" -d "$REPMGR_DB" standby register    
fi
