app "westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.1/dCL3KsovvV-8A5D_W_0X_abynkcRcoAngsgF0xtvQsk.tar.br",
        html: "https://github.com/Hasnep/roc-html/releases/download/v0.2.0/5fqQTpMYIZkigkDa2rfTc92wt-P_lsa76JVXb8Qb3ms.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.0/hJySbEhJV026DlVCHXGOZNOeoOl7468y9F9Buhj0J18.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        pf.Utc,
        pf.Env,
        pf.Url,
        pf.Command,
        html.Html,
        json.Core.{ json },
        Decode.{ DecodeResult, DecodeError },
        # "init_db.sql" as initDbSql : List U8,
    ]
    provides [main] to pf

#  Step 1
# - basic profiling with timestamps
# - db initialization
# - fill db with currently known events in Jan und Feb 24
# - Render this list to index.html
# - Imprint.html
# - 404.html
# - deploy this version

#  Step 2
# - Render detail pages for events
# - link to detail pages from index
# - deploy

#
# - admin api to update entrie via postman
# - deploy

#
# Elm Admin Backend
# deploy

# [- add JWT to platform]
# [- add sqlite3 to platform]
# [- CSS builder]
# - initDb should run once only. maybe add a 'init : {} -> Task initialData []' to the platform

main : Request -> Task Response []
main = \req ->
    info <- Utc.now |> Task.map (\startTime -> @RequestInfo { req, startTime }) |> Task.await
    {} <- Stdout.line "\(displayStartTime info) \(Http.methodToStr req.method) \(req.url)" |> Task.await

    maybeDbPath <- Env.var "DB_PATH" |> Task.attempt

    handlerResponse =
        when req.url |> Url.fromStr |> Url.path |> Str.split "/" is
            ["", ""] -> routeIndex maybeDbPath info
            ["", "events"] -> Task.ok (TextResponse "events" OK) # renderEvent
            _ -> Task.err (UnknownRoute info) # renderNotFound

    handlerResponse
    |> Task.onErr handleServerError
    |> Task.map toResponse

# =================================================
#   - Index && EventList
# =================================================
routeIndex : Result Str [VarNotFound], RequestInfo -> HandlerResult
routeIndex = \maybeDbPath, info ->
    when (maybeDbPath, method info) is
        (Ok dbPath, Get) ->
            renderEventsList dbPath info

        _ -> Task.err (UnknownRoute info)

renderEventsList : Str, RequestInfo -> HandlerResult
renderEventsList = \dbPath, info ->
    events <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg ".mode json"
        |> Command.arg "SELECT id, slug, title, location, description, startsAt, endsAt from events;"
        |> Command.output
        |> Task.await \output ->
            when output.status is
                Ok {} -> Task.ok output.stdout
                Err _ -> Task.err (DBError dbPath info)
        |> Task.await
            (\bytes ->
                when bytes |> decodeEvent is
                    Ok decoded ->
                        Task.ok decoded

                    Err _ ->
                        Task.err (DecodeError bytes info)
            )
        |> Task.await

    eventList = Html.ul [] (events |> List.map \{ title, location } -> Html.li [] [Html.text "\(title) at \(location)"])

    Html.html [] [
        Html.body [] [
            Html.h1 [] [Html.text "Westies HB"],
            eventList,
        ],
    ]
    |> HtmlResponse OK
    |> Task.ok

# =================================================
#   - Event Type
# =================================================

Event : {
    id : I32,
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    startsAt : U128,
    endsAt : U128,
}

decodeEvent : List U8 -> Result (List Event) _
decodeEvent = \str -> str
    |> Decode.fromBytes json

# ==================================================================================================

# =================================================
#   - Request Info
# =================================================
RequestInfo := {
    req : Request,
    startTime : Utc.Utc,
}

displayStartTime : RequestInfo -> Str
displayStartTime = \@RequestInfo { startTime: time } ->
    Utc.toIso8601Str time

method : RequestInfo -> Http.Method
method = \@RequestInfo { req } ->
    req.method

# =================================================
#   - Handling Server Response
# =================================================

ServerError : [
    DBError Str RequestInfo,
    DecodeError (List U8) RequestInfo,
    UnknownRoute RequestInfo,
]

Status : [
    # 2xx success
    OK,

    # 4xx client errors
    BadRequest,
    Unauthorized,
    Forbidden,
    NotFound,

    # 5xx server errors
    InternalServerError,
]

statusToU16 : Status -> U16
statusToU16 = \code ->
    when code is
        OK -> 200
        BadRequest -> 400
        Unauthorized -> 401
        Forbidden -> 403
        NotFound -> 404
        InternalServerError -> 500

ServerResponse : [
    HtmlResponse Html.Node Status,
    TextResponse Str Status,
    JsonResponse (List U8) Status,
]

HandlerResult : Task ServerResponse ServerError

toResponse : ServerResponse -> Response
toResponse = \result ->
    when result is
        HtmlResponse body s ->
            body
            |> Html.render
            |> Str.toUtf8
            |> byteResponse (statusToU16 s)

        TextResponse body s ->
            textResponse body (statusToU16 s)

        JsonResponse body s ->
            jsonResponse body (statusToU16 s)

handleServerError : ServerError -> Task ServerResponse []
handleServerError = \error ->
    errPage = \errTitle, errTxt, status ->
        Html.html [] [
            Html.body [] [
                Html.h1 [] [Html.text "Westies HB - ERROR"],
                Html.div [] [
                    Html.h2 [] [Html.text errTitle],
                    Html.p [] [Html.text errTxt],
                ],
            ],
        ]
        |> HtmlResponse status
        |> Task.ok

    when error is
        DBError dbPath _ ->
            {} <- Stderr.line "DB Error: \(dbPath)" |> Task.await
            errPage "DB Error" "Could not access DB." InternalServerError

        DecodeError bytes _ ->
            jsonStr =
                (Str.fromUtf8 bytes)
                |> Result.withDefault "UTF8 error"
            {} <- Stderr.line "Decode Error:\n\(jsonStr)" |> Task.await
            errPage "Decode Error" "Could not decode events from DB." InternalServerError

        UnknownRoute _ ->
            {} <- Stderr.line "UnknownRoute" |> Task.await
            errPage "404" "UnknownRoute" NotFound

jsonResponse : List U8, U16 -> Response
jsonResponse = \bytes, status -> {
    status,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "application/json; charset=utf-8" },
    ],
    body: bytes,
}

textResponse : Str, U16 -> Response
textResponse = \str, status -> {
    status,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
    ],
    body: Str.toUtf8 str,
}

byteResponse : List U8, U16 -> Response
byteResponse = \bytes, status -> {
    status,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
    ],
    body: bytes,
}

