app "westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.0/hJySbEhJV026DlVCHXGOZNOeoOl7468y9F9Buhj0J18.tar.br",
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
