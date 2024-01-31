# roc format ./src/server.roc

DB_PATH=./data/data.db roc dev --prebuilt-platform --linker=legacy ./src/server.roc 
