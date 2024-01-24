rm -rf data

mkdir data

DB_PATH=./data/data.db
INIT_DB_SCRIPT=./db/init_db.sql
SEED_DB_SCRIPT=./db/seed.sql

sqlite3 data/data.db ".read db/init_db.sql" 
sqlite3 data/data.db ".read db/seed.sql" 

