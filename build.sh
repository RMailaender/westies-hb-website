rm -rf build 

mkdir build 
mkdir build/data

pnpm run build:elm

roc format ./src/server.roc

roc build ./src/server.roc --optimize --output ./build/server

sqlite3 build/data/data.db ".read db/init_db.sql" 
