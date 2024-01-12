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
        pf.File,
        pf.Path,
        html.Attribute.{ class },
        json.Core.{ json },
        Decode.{ DecodeResult },
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
            ["", ""] ->
                routeIndex maybeDbPath info

            ["", "events"] ->
                routeIndex maybeDbPath info

            ["", "events", slug] ->
                routeEvent maybeDbPath slug info

            ["", "public", "style.css"] ->
                File.readBytes (Path.fromStr "public/style.css")
                |> Task.await \f -> Task.ok (CssResponse f)
                |> Task.onErr (\_ -> Task.ok (TextResponse "events" HttpOK))

            _ -> Task.err (UnknownRoute)

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
            renderEventsList dbPath

        _ -> Task.err (UnknownRoute)

renderEventsList : Str -> HandlerResult
renderEventsList = \dbPath ->
    events <- publicEvents dbPath |> Task.await

    pageLayout {
        title: "Westies HB",
        content: Html.div [] [
            Html.h2 [] [Html.text "Events"],
            monthSection events,
        ],
    }
    |> HtmlResponse HttpOK
    |> Task.ok

monthSection : List Event -> Html.Node
monthSection = \events ->
    eventSections = List.map events \{ title, slug, location } ->
        Html.section [] [
            Html.h3 [] [Html.a [Attribute.href "/events/\(slug)"] [Html.text title]],
            Html.p [] [Html.text location],
        ]

    Html.section
        []
        (
            [
                Html.h2 [] [Html.text "Januar"],
            ]
            |> List.concat eventSections
        )
# =================================================
#   - EventDetails
# =================================================
routeEvent : Result Str [VarNotFound], Str, RequestInfo -> HandlerResult
routeEvent = \maybeDbPath, slug, info ->
    when (maybeDbPath, method info) is
        (Ok dbPath, Get) ->
            renderEvent dbPath slug

        _ -> Task.err (UnknownRoute)

renderEvent : Str, Str -> HandlerResult
renderEvent = \dbPath, slug ->
    events <- publicEventBySlug dbPath slug |> Task.await

    when List.first events is
        Ok { title, description } ->
            pageLayout {
                title: "Westies HB - \(title)",
                content: Html.div [] [
                    Html.h2 [] [Html.text title],
                    Html.p [] [Html.text description],
                ],
            }
            |> HtmlResponse HttpOK
            |> Task.ok

        Err _ -> Task.err UnknownRoute

# =================================================
#   - Event
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

publicEventBySlug : Str, Str -> Task (List Event) ServerError
publicEventBySlug = \dbPath, slug ->
    jsonLite dbPath
    |> queryDb "SELECT id, slug, title, location, description, startsAt, endsAt from events WHERE public=1 AND slug=\"\(slug)\";" decodeEvent

publicEvents : Str -> Task (List Event) ServerError
publicEvents = \dbPath ->
    jsonLite dbPath
    |> queryDb "SELECT id, slug, title, location, description, startsAt, endsAt from events WHERE public=1;" decodeEvent

decodeEvent : List U8 -> Result (List Event) [JsonDecodeError Str (List U8)]
decodeEvent = \bytes ->
    when Decode.fromBytes bytes json is
        Ok events -> Ok events
        Err _ -> Err (JsonDecodeError "Events" bytes)

# =================================================
#   - View Components
# =================================================
pageLayout :
    {
        title : Str,
        content : Html.Node,
    }
    -> Html.Node
pageLayout = \{ title, content } ->
    # style = styleCss |> Str.fromUtf8 |> Result.withDefault ""
    Html.html [] [
        Html.head [] [
            Html.meta [Attribute.charset "utf-8"] [],
            Html.link [Attribute.rel "stylesheet", Attribute.href "/public/style.css"] [],
            Html.title [] [Html.text title],

        ],
        Html.body [] [
            Html.header [class "top-header"] [
                Html.nav [Attribute.id "main-nav"] [
                    Html.h1 [] [
                        Html.a [Attribute.href "/events"] [Html.text title],
                    ],
                ],
            ],
            Html.main [] [
                content,
            ],
            Html.footer [] [],
        ],
    ]

# =================================================
#   - Sqlite
# =================================================
Mode : [Json]
Sqlite := {
    dbPath : Str,
    mode : Mode,
}

jsonLite : Str -> Sqlite
jsonLite = \dbPath ->
    @Sqlite { dbPath, mode: Json }

queryDb : Sqlite, Str, (List U8 -> Result decoded [JsonDecodeError Str (List U8)]) -> Task decoded ServerError
queryDb = \@Sqlite { dbPath, mode }, query, decode ->
    modeArg =
        when mode is
            Json -> ".mode json"

    bytes <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg modeArg
        |> Command.arg query
        |> Command.output
        |> Task.await \output ->
            when output.status is
                Ok {} ->
                    Task.ok output.stdout

                Err _ ->
                    err = (Str.fromUtf8 output.stderr) |> Result.withDefault "shit" |> Str.toUtf8
                    Task.err (DBCommandFailed dbPath err)
        |> Task.await

    when decode bytes is
        Ok decoded -> Task.ok decoded
        Err (JsonDecodeError name b) -> Task.err (JsonDecodeError name b)

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
    DBCommandFailed Str (List U8),
    JsonDecodeError Str (List U8),
    UnknownRoute,
    CouldNotLoadCssError,
    EnvNotFound Str,
]

Status : [
    # 2xx success
    HttpOK,

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
        HttpOK -> 200
        BadRequest -> 400
        Unauthorized -> 401
        Forbidden -> 403
        NotFound -> 404
        InternalServerError -> 500

ServerResponse : [
    HtmlResponse Html.Node Status,
    TextResponse Str Status,
    JsonResponse (List U8) Status,
    CssResponse (List U8),
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

        CssResponse body ->
            cssResponse body (statusToU16 HttpOK)

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
        DBCommandFailed dbPath _ ->
            {} <- Stderr.line "DB Error: \(dbPath)" |> Task.await
            errPage "DB Error" "Could not access DB." InternalServerError

        JsonDecodeError name bytes ->
            jsonStr =
                (Str.fromUtf8 bytes)
                |> Result.withDefault "UTF8 error"
            {} <- Stderr.line "Decode Error -> \(name):\n\(jsonStr)" |> Task.await
            errPage "Decode Error" "Could not decode events from DB." InternalServerError

        UnknownRoute ->
            {} <- Stderr.line "UnknownRoute" |> Task.await
            errPage "404" "UnknownRoute" NotFound

        CouldNotLoadCssError ->
            {} <- Stderr.line "CouldNotLoadCssError" |> Task.await
            Task.ok (TextResponse "CouldNotLoadCssError" InternalServerError)

        EnvNotFound env ->
            {} <- Stderr.line "Env not found: \(env)" |> Task.await
            errPage "Env not found" "Could not find env: \(env)" InternalServerError

jsonResponse : List U8, U16 -> Response
jsonResponse = \bytes, status -> {
    status,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "application/json; charset=utf-8" },
    ],
    body: bytes,
}

cssResponse : List U8, U16 -> Response
cssResponse = \bytes, status -> {
    status,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "text/css; charset=utf-8" },
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

