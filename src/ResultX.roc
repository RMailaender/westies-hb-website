interface ResultX
    exposes [
        orElse,
    ]
    imports [

    ]

orElse : Result ok err, (err -> ok) -> ok
orElse = \result, onErr ->
    when result is
        Ok ok -> ok
        Err err -> onErr err

