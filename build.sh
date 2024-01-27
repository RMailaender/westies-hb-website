rm -rf build 

mkdir build 

roc format ./src/server.roc

roc build ./src/server.roc --linker=legacy --output ./build/server

sqlite3 build/data.db ".read db/init_db.sql" 
sqlite3 build/data.db ".read db/seed.sql" 
