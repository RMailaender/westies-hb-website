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
        pf.Url.{ Url },
        pf.Command,
        html.Html,
        html.Attribute.{ class },
        json.Core.{ json },
        Decode.{ DecodeResult },
        Inspect,
        "style.css" as styleFile : List U8,
        Time.{ TimeOffset },
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

cet = Time.customZone (After (60 * 60)) []

main : Request -> Task Response []
main = \req ->
    time <-
        Utc.now
        |> Task.map Utc.toNanosSinceEpoch
        |> Task.map Time.posixFromNanos
        |> Task.await

    dt = Time.toDateTime time cet

    {} <- Stdout.line "$(Time.displayDt dt) \(Http.methodToStr req.method) \(req.url)" |> Task.await

    dbPath <-
        Env.var "DB_PATH"
        |> Task.onErr \_ -> crash "Unable to read DB_PATH"
        |> Task.await

    handlerResponse =
        when (req.method, req.url |> Url.fromStr |> urlSegments) is
            (Get, [""]) | (Get, ["events"]) ->
                indexPage dbPath

            (Get, ["events", slug]) ->
                {} <- Stdout.line "hier" |> Task.await
                eventDetailPage dbPath slug

            (Get, ["style.css"]) ->
                Task.ok (CssResponse styleFile)

            _ -> Task.err (UnknownRoute)

    handlerResponse
    |> Task.onErr handleServerError
    |> Task.map toResponse

# =================================================
#   - Index && EventList
# =================================================
indexPage : Str -> HandlerResult
indexPage = \dbPath ->

    events <- publicEvents dbPath |> Task.await

    pageLayout {
        title: "Westies HB",
        content: [
            eventsMonthSection events "Januar",
            eventsMonthSection events "Februar",
        ],
    }
    |> HtmlResponse HttpOK
    |> Task.ok

monthWithPaddedZeros : U128 -> Str
monthWithPaddedZeros = \month ->
    monthStr = Num.toStr month
    if month < 10 then
        "0$(monthStr)"
    else
        monthStr

dayWithPaddedZeros : U128 -> Str
dayWithPaddedZeros = monthWithPaddedZeros

eventsMonthSection : List Event, Str -> Html.Node
eventsMonthSection = \events, month ->
    expect
        "one" == month

    eventListItem = \event ->
        expect
            event.slug == ""

        startsAt =
            event.startsAt
            |> Time.toDateTime cet
            |> \dt ->
                "$(dayWithPaddedZeros dt.day).$(monthWithPaddedZeros dt.month)"

        expect startsAt == ""

        Html.div [class "event-list-item"] [
            Html.div [class "event-list-item--head"] [Html.text startsAt],
            Html.div [class "event-list-item--body"] [
                Html.a [Attribute.href "/events/$(event.slug)"] [Html.text event.title],
            ],
        ]

    eventsInHb =
        events
        |> List.keepIf (\{ location } -> Str.contains "Bremen" location)
        |> List.map eventListItem
        |> \hbEvents ->
            when hbEvents is
                [] -> Html.text ""
                lst ->
                    Html.div [class "events-month-group"] [
                        Html.h3 [] [Html.text "In Bremen"],
                        Html.div [class "event-list"] lst,
                    ]
    eventsOutsideHb =
        events
        |> List.dropIf (\{ location } -> Str.contains "Bremen" location)
        |> List.map eventListItem
        |> \hbEvents ->
            when hbEvents is
                [] -> Html.text ""
                lst ->
                    Html.div [class "events-month-group"] [
                        Html.h3 [] [Html.text "Umzu"],
                        Html.div [class "event-list"] lst,
                    ]

    Html.section [class "events-month-section"] [
        Html.h2 [] [Html.text month],
        eventsInHb,
        eventsOutsideHb,
    ]

# =================================================
#   - EventDetails
# =================================================
eventDetailPage : Str, Str -> HandlerResult
eventDetailPage = \dbPath, slug ->
    event <- publicEventBySlug slug dbPath |> Task.attempt
    {} <- Stdout.line "event from db $(Inspect.toStr event)" |> Task.await

    when event is
        Ok { title, description } ->
            pageLayout {
                title: "Westies HB - \(title)",
                content: [
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

publicEventBySlug : Str, Str -> Task Event _
publicEventBySlug = \slug, dbPath ->
    "SELECT id, slug, title, location, description, startsAt, endsAt from events WHERE public=1 AND slug=\"$(slug)\";"
    |> executeSql dbPath
    |> Task.await \bytes ->
        when Decode.fromBytes bytes json is
            Err err -> Task.err (SqlParsingError err)
            Ok events ->
                events
                |> List.map eventFromDb
                |> List.first
                |> Task.fromResult

publicEvents : Str -> Task (List Event) ServerError
publicEvents = \dbPath ->
    jsonLite dbPath
    |> queryDbOld "SELECT id, slug, title, location, description, startsAt, endsAt from events WHERE public=1;" decodeEvent
    |> Task.map \events ->
        events
        |> List.map eventFromDb

decodeEvent : List U8 -> Result (List EventDb) [JsonDecodeError Str (List U8)]
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
        content : List Html.Node,
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
            Html.main [] content,
            Html.footer [] [],

        ],
    ]

# =================================================
#   - helper
# =================================================
urlSegments : Url -> List Str
urlSegments = \url -> url |> Url.path |> Str.split "/" |> List.dropFirst 1

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

executeSql : Str, Str -> Task (List U8) _
executeSql = \query, dbPath ->
    Command.new "sqlite3"
    |> Command.arg dbPath
    |> Command.arg ".mode json"
    |> Command.arg query
    |> Command.output
    |> Task.await
        \output ->
            when output.status is
                Ok {} ->
                    Task.ok output.stdout

                Err _ ->
                    err = (Str.fromUtf8 output.stderr) |> Result.withDefault "shit"
                    {} <- Stdout.line "executeSql Err: $(err) " |> Task.await
                    Task.err (DBCommandFailed dbPath err)

queryDbOld : Sqlite, Str, (List U8 -> Result decoded [JsonDecodeError Str (List U8)]) -> Task decoded ServerError
queryDbOld = \@Sqlite { dbPath, mode }, query, decode ->
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
                    err = (Str.fromUtf8 output.stderr) |> Result.withDefault "shit"
                    Task.err (DBCommandFailed dbPath err)
        |> Task.await

    when decode bytes is
        Ok decoded -> Task.ok decoded
        Err (JsonDecodeError name b) -> Task.err (JsonDecodeError name b)

# ==================================================================================================

# =================================================
#   - Handling Server Response
# =================================================

ServerError : [
    DBCommandFailed Str Str,
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

