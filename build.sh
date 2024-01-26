rm -rf build 

mkdir build 
mkdir build/data

roc format ./src/server.roc

roc build ./src/server.roc --linker=legacy --output ./build/server

sqlite3 build/data/data.db ".read db/init_db.sql" 
sqlite3 build/data/data.db ".read db/seed.sql" 
