rm -rf build 

mkdir build 
mkdir build/public
mkdir build/data

cp public/style.css build/public/style.css

pnpm run build:elm

roc format ./src/roc-server/server.roc

roc build ./src/roc-server/server.roc --optimize --output ./build/server

sqlite3 build/data/data.db ".read db/init_db.sql" 
