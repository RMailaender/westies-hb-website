app "westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.7.1/Icc3xJoIixF3hCcfXrDwLCu4wQHtNdPyoJkEbkgIElA.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.1/-7UaQL9fbi0J3P6nS_qlxTdpDkOu_7CUm4MZzAN9ZUQ.tar.br",
    }
    imports [
        pf.Task.{ Task },
        pf.Stdout,
        json.Core.{ json },
        Decode,
        "events.json" as eventsJsonFile : List U8,
    ]
    provides [main] to pf

main : Task {} _
main =

    events
    |> List.map \event -> "- $(event.slug)"
    |> Str.joinWith "\n"
    |> Stdout.line

events : List Event
events =
    eventsJsonFile
    |> Decode.fromBytesPartial json
    |> \{ result } -> result
    |> Result.withDefault []

Event : {
    id : I32,
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    startsAt : U128,
    endsAt : U128,
}
