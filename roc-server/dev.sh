
roc build ./src/server.roc --linker legacy --output ./roc-out/dev/server

source ./setenv.sh

./roc-out/dev/server
