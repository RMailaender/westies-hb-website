app "westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.1/dCL3KsovvV-8A5D_W_0X_abynkcRcoAngsgF0xtvQsk.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.0/hJySbEhJV026DlVCHXGOZNOeoOl7468y9F9Buhj0J18.tar.br",
    }
    imports [
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        json.Core.{ json },
        Decode,
        "events.json" as eventsJsonFile : List U8,
    ]
    provides [main] to pf

main : Request -> Task Response []
main = \_ ->

    events
    |> List.map \event -> "- $(event.slug)"
    |> Str.joinWith "\n"
    |> \str -> {
        status: 200,
        headers: [
            { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
        ],
        body: Str.toUtf8 str,
    }
    |> Task.ok

events : List Event
events =
    eventsJsonFile
    |> Decode.fromBytes json
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
