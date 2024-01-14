roc format ./src/roc-server/server.roc

roc build ./src/roc-server/server.roc --linker legacy --output ./build/server

source ./setenv.sh

./build/server
