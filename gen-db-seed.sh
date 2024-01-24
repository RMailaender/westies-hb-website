# SEED_DB_SCRIPT=./db/seed.sql

roc build ./src/SeedDb.roc

./src/SeedDb > ./db/seed.sql

rm ./src/SeedDb