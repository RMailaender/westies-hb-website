rm -rf build 

mkdir build 

roc format ./src/server.roc

roc build ./src/server.roc --linker=legacy --output ./build/server
