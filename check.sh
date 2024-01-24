src='./src/'

# roc check
for roc_file in $src*.roc; do
    roc format $roc_file
done

roc check ./src/server.roc