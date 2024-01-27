app "westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.1/dCL3KsovvV-8A5D_W_0X_abynkcRcoAngsgF0xtvQsk.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.0/hJySbEhJV026DlVCHXGOZNOeoOl7468y9F9Buhj0J18.tar.br",
    }
    imports [
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        json.Core.{ json },
        Decode.{ DecodeResult },
        "events.json" as eventsJsonFile : List U8,
        Time.{ TimeOffset },
    ]
    provides [main] to pf

main : Request -> Task Response []
main = \_ ->

    eventsJsonFile
    |> Decode.fromBytes json
    |> Result.withDefault []
    |> List.map eventFromDb
    |> List.map \event -> "- $(event.slug)"
    |> Str.joinWith "\n"
    |> textResponse 200
    |> Task.ok

# =================================================
#   - Event
# =================================================

Event : {
    id : I32,
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    startsAt : Time.Posix,
    endsAt : Time.Posix,
}

eventFromDb : EventDb -> Event
eventFromDb = \{ id, slug, title, location, description, startsAt, endsAt } -> {
    id,
    slug,
    title,
    location,
    description,
    startsAt: Time.posixFromSeconds startsAt,
    endsAt: Time.posixFromSeconds endsAt,
}

EventDb : {
    id : I32,
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    startsAt : U128,
    endsAt : U128,
}

textResponse : Str, U16 -> Response
textResponse = \str, status -> {
    status,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
    ],
    body: Str.toUtf8 str,
}

