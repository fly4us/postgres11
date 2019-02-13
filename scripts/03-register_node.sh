#!/bin/bash
 
set -ex

PGHOST=${PRIMARY_NODE}
 
installed=$(psql -qAt -h "$PGHOST" -U "$REPMGR_USER" "$REPMGR_DB" -c "SELECT 1 FROM pg_tables WHERE tablename='nodes'")
 
if [ "${installed}" != "1" ]; then
    echo '~~ 03: registering as primary' >&2
    env PGPASSFILE=/var/lib/postgresql/.pgpass repmgr -f ${PGDATA}/repmgr.conf --verbose primary register
    return
fi

if [ -n "$WITNESS" ]; then
	echo '~~ 03: registering as witness server' >&2
	repmgr -f ${PGDATA}/repmgr.conf -h "$PRIMARY_NODE" -U "$REPMGR_USER" -d "$REPMGR_DB" witness register
	return
fi
 
my_node=$(grep node_id /etc/repmgr.conf | cut -d= -f 2)
is_reg=$(psql -qAt -h "$PGHOST" -U "$REPMGR_USER" "$REPMGR_DB" -c "SELECT 1 FROM repmgr.nodes WHERE node_id=${my_node}")
 
if [ "${is_reg}" != "1" ] && [ ${my_node} -gt 1 ]; then
    echo '~~ 03: registering as standby' >&2
    pg_ctl -D "$PGDATA" stop -m fast
    rm -Rf "$PGDATA"/*
    repmgr -f ${PGDATA}/repmgr.conf -h "$PRIMARY_NODE" -U "$REPMGR_USER" -d "$REPMGR_DB" standby clone --fast-checkpoint
    cp /etc/postgresql/11/main/postgresql.conf ${PGDATA}/
    pg_ctl -D "$PGDATA" start &
    sleep 1
    repmgr -f ${PGDATA}/repmgr.conf -h "$PRIMARY_NODE" -U "$REPMGR_USER" -d "$REPMGR_DB" standby register    
fi
