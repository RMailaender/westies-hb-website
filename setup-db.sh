roc build ./src/setup.roc --output ./roc-out/dev/setup

export DB_PATH=./data/data.db

# sqlite3 $DB_PATH .read "./src/init_db.sql" 

./roc-out/dev/setup