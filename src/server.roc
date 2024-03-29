app "westies-hb-server"
    packages {
        pf: "../../roc/basic-webserver/platform/main.roc",
        html: "https://github.com/Hasnep/roc-html/releases/download/v0.2.0/5fqQTpMYIZkigkDa2rfTc92wt-P_lsa76JVXb8Qb3ms.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.1/-7UaQL9fbi0J3P6nS_qlxTdpDkOu_7CUm4MZzAN9ZUQ.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        # pf.File,
        # pf.Path,
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

cet = Time.customZone (After (60 * 60)) []

main : Request -> Task Response []
main = \req ->

    time <-
        Utc.now
        |> Task.await

    timeStr = Utc.toIso8601Str time
    {} <- Stdout.line "$(timeStr) $(Http.methodToStr req.method) $(req.url)" |> Task.await

    dbPath <-
        Env.var "DB_PATH"
        |> Task.onErr \_ -> Task.ok "./build/data.db"
        |> Task.await

    handlerResponse =
        when (req.method, req.url |> Url.fromStr |> urlSegments) is
            (Get, [""]) | (Get, ["events"]) ->
                indexPage time dbPath

            (Get, ["events", slug]) ->
                {} <- Stdout.line "hier" |> Task.await
                eventDetailPage dbPath slug

            (Get, ["style.css"]) ->
                Task.ok (CssResponse styleFile)

            # File.readBytes (Path.fromStr "src/style.css")
            # |> Task.mapErr \_ -> FileIOError
            # |> Task.map CssResponse
            _ -> Task.err (UnknownRoute req.url)

    handlerResponse
    |> Task.onErr handleServerError
    |> Task.map toResponse

# =================================================
#   - Index && EventList
# =================================================
indexPage : Utc.Utc, Str -> HandlerResult
indexPage = \utc, dbPath ->

    events <-
        utc
        |> Utc.toNanosSinceEpoch
        |> Num.toU128
        |> Time.posixFromNanos
        |> publicEvents dbPath
        |> Task.await

    events
    |> List.walk (Dict.empty {}) \state, event ->
        dt =
            event.startsAt
            |> Time.toDateTime cet

        key =
            (dt.year * 10) + (Time.monthToU128 dt.month)

        state
        |> Dict.update key \possibleValue ->
            when possibleValue is
                Missing ->
                    title = "$(Time.toGermanMonth dt.month) $(Num.toStr dt.year)"
                    Present (title, [event])

                Present (title, lst) ->
                    Present (title, List.append lst event)
    |> Dict.walk
        []
        \state, _, (monthTitle, monthEvents) -> state |> List.append (eventsMonthSection monthEvents monthTitle)
    |> \content -> [Html.div [class "events-main"] content]
    |> \content -> pageLayout { title: "Westies HB", content }
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

eventsMonthSection : List EventListEntry, Str -> Html.Node
eventsMonthSection = \events, month ->

    eventListItem = \event ->

        startsAt =
            event.startsAt
            |> Time.toDateTime cet
            |> \dt ->
                "$(dayWithPaddedZeros dt.day).$(monthWithPaddedZeros (Time.monthToU128 dt.month))"

        Html.div [class "event-list-item"] [
            Html.div [class "event-list-item--head"] [Html.text startsAt],
            Html.div [class "event-list-item--body"] [
                Html.a [Attribute.href "/events/$(event.slug)"] [Html.text event.title],
            ],
        ]

    eventsInHb =
        events
        |> List.keepIf \{ location } -> Str.contains location "Bremen"
        |> List.map eventListItem
        |> \hbEvents ->
            when hbEvents is
                [] -> Html.text ""
                lst ->
                    Html.div [class "events-month-group"] [
                        Html.div [class "events-month-group-header"] [Html.h3 [] [Html.text "In Bremen"]],
                        Html.div [class "events-month-group-event-list"] lst,
                    ]
    eventsOutsideHb =
        events
        |> List.dropIf \{ location } -> Str.contains location "Bremen"
        |> List.map eventListItem
        |> \hbEvents ->
            when hbEvents is
                [] -> Html.text ""
                lst ->
                    Html.div [class "events-month-group"] [
                        Html.div [class "events-month-group-header"] [Html.h3 [] [Html.text "Umzu"]],
                        Html.div [class "events-month-group-event-list"] lst,
                    ]

    Html.section [class "events-month-section"] [
        Html.div [class "events-month-section-header"] [Html.h2 [] [Html.text month]],
        Html.div [class "events-month-section-body"] [
            eventsInHb,
            eventsOutsideHb,
        ],
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

        Err _ -> Task.err (UnknownRoute "events/$(slug)")

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

EventListEntry : {
    slug : Str,
    startsAt : Time.Posix,
    title : Str,
    location : Str,
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
            Err _ -> Task.err (SqlParsingError "publicEventBySlug")
            Ok events ->
                events
                |> List.map eventFromDb
                |> List.first
                |> Task.fromResult

publicEvents : Time.Posix, Str -> Task (List EventListEntry) _
publicEvents = \today, dbPath ->
    toEntry : { slug : Str, title : Str, location : Str, startsAt : U128 } -> EventListEntry
    toEntry = \{ slug, title, location, startsAt } -> {
        slug,
        title,
        location,
        startsAt: (startsAt |> Time.posixFromSeconds),
    }

    today
    |> Time.sub (Days 1)
    |> Time.posixToSeconds
    |> Num.toStr
    |> \timeStr -> "SELECT slug, title, location, startsAt from events WHERE public=1 AND startsAt>=$(timeStr);"
    |> executeSql dbPath
    |> Task.await \bytes ->
        when Decode.fromBytes bytes json is
            Err _ -> Task.err (SqlParsingError "publicEvents")
            Ok events ->
                events
                |> List.map toEntry
                |> Task.ok

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
            Html.meta [Attribute.name "viewport", Attribute.content "width=device-width"] [],
            Html.link [Attribute.rel "stylesheet", Attribute.href "/style.css"] [],
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
# ================================================

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

# ==================================================================================================

# =================================================
#   - Handling Server Response
# =================================================

ServerError : [
    DBCommandFailed Str Str,
    UnknownRoute Str,
    EnvNotFound Str,
    SqlParsingError Str,
    FileIOError,
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
            {} <- Stderr.line "|--> DB Error: $(dbPath)" |> Task.await
            errPage "DB Error" "Could not access DB." InternalServerError

        SqlParsingError s ->
            {} <- Stderr.line "|--> SqlParsingError: $(s)" |> Task.await
            errPage "DB Error" "Could not access DB." InternalServerError

        UnknownRoute route ->
            {} <- Stderr.line "|--> 404 UnknownRoute: $(route)" |> Task.await
            errPage "404" "UnknownRoute" NotFound

        EnvNotFound env ->
            {} <- Stderr.line "|--> Env not found: $(env)" |> Task.await
            errPage "Env not found" "Could not find env: $(env)" InternalServerError

        FileIOError ->
            {} <- Stderr.line "|--> FileIOError" |> Task.await
            errPage "File io error" "Could not read file" InternalServerError

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

