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
        pf.File.{ ReadErr },
        pf.Path,
        # pf.Command,
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
    startTime <- Utc.now |> Task.await

    result <- handleRequest req |> Task.attempt

    endTime <- Utc.now |> Task.await

    dt = Utc.deltaAsMillis startTime endTime

    when result is
        Ok res ->
            {} <- Stdout.line
                    "SUCCESS \t\(Num.toStr dt) ms \t\(Utc.toIso8601Str startTime) \(Http.methodToStr req.method) \(req.url)"
                |> Task.await
            Task.ok res

        Err err ->
            errStr =
                when err is
                    JsonFileReadErr path _ ->
                        "JsonFileReadErr \(Path.display path)"

                    JsonDecodeError ->
                        "JsonDecodeError"

                    EnvMissingError var ->
                        "Env missing '\(var)'"

            {} <- Stderr.line
                    "ERROR \t\(Num.toStr dt)ms \t\(Utc.toIso8601Str startTime) \(Http.methodToStr req.method) \(req.url)\n |> \(errStr)"
                |> Task.await
            Task.ok { status: 500, headers: [], body: Str.toUtf8 "some error dude" }

# initDb : {} -> Str
# initDb = \{} ->
#     dbPath <-
#         Env.var "DB_PATH"
#         |> Task.onErr \_ -> Task.err EnvMissingError
#         |> Task.await

#     maybeDb <- File.readBytes (Path.fromStr dbPath) |> Task.attempt

#     when maybeDb is
#         Ok db -> Task.ok AllesGut
#         _ ->
#             when Str.fromUtf8 initDbSql is
#                 Ok initDbStr ->
#                     output <-
#                         #  create custom sqlite function
#                         Command.new "sqlite3"
#                         |> Command.arg dbPath
#                         |> Command.arg ".mode json"
#                         |> Command.arg initDbStr
#                         |> Command.output
#                         |> Task.await

#                     when output.status is
#                         Ok _ -> Task.ok DbCreated
#                         _ -> Task.err DbCreationWentWrong

#                 Err _ ->
#                     Task.err MalformedInitDbSqlError

#  remove data.json stuff
readJson : Path.Path, (List U8 -> Result val err) -> Task val [JsonFileReadErr Path.Path ReadErr, JsonDecodeError]
readJson = \jsonPath, decode ->
    maybeBytes <- (File.readBytes jsonPath) |> Task.attempt
    when maybeBytes is
        Ok bytes ->
            when decode bytes is
                Ok data ->
                    Task.ok data

                Err _ ->
                    Task.err (JsonDecodeError)

        Err (FileReadErr path readErr) ->
            Task.err (JsonFileReadErr path readErr)

handleRequest : Request -> Task Response [EnvMissingError Str, JsonFileReadErr Path.Path ReadErr, JsonDecodeError]
handleRequest = \req ->
    # date <- Utc.now |> Task.map Utc.toIso8601Str |> Task.await
    # {} <- Stdout.line "\(date) \(Http.methodToStr req.method) \(req.url)" |> Task.await

    #  remove data.json stuff
    events <-
        Env.var "DATA"
        |> Task.attempt \maybeVar ->
            when maybeVar is
                Ok var if !(Str.isEmpty var) -> Task.ok var
                _ -> Task.err (EnvMissingError "DATA")
        |> Task.await \dataPath -> readJson (Path.fromStr dataPath) decodeEvent
        |> Task.await

    # {} <- Stdout.line "\(date) \(Http.methodToStr req.method) \(req.url)" |> Task.await

    eventList = Html.ul [] (events |> List.map \{ title, location } -> Html.li [] [Html.text "\(title) at \(location)"])

    res =
        Html.html [] [
            Html.body [] [
                Html.h1 [] [Html.text "Epic Hacking Website"],
                Html.div [] [eventList],
            ],
        ]
        |> Html.render

    # Respond with request body
    when req.body is
        EmptyBody -> Task.ok { status: 200, headers: [], body: Str.toUtf8 "hello there" }
        Body _ -> Task.ok { status: 200, headers: [], body: Str.toUtf8 res }

Event : {
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    start : U128,
}

decodeEvent : List U8 -> Result (List Event) _
decodeEvent = \str -> str
    |> Decode.fromBytes json
