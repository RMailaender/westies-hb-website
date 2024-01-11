app "setup-westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.7.1/Icc3xJoIixF3hCcfXrDwLCu4wQHtNdPyoJkEbkgIElA.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.0/hJySbEhJV026DlVCHXGOZNOeoOl7468y9F9Buhj0J18.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Cmd,
        pf.Task.{ Task },
        pf.Env,
        Decode.{ DecodeResult, DecodeError },
        # "init_db.sql" as initDbSql : List U8,
    ]
    provides [main] to pf

main : Task {} I32
main =
    maybeDbPath <- Env.var "DB_PATH" |> Task.attempt

    when maybeDbPath is
        Ok dbPath ->
            initDb dbPath

        Err _ ->
            Task.ok {}

initDb : Str -> Task {} I32
initDb = \dbPath ->
    result <-
        Cmd.new "sqlite3"
        |> Cmd.arg dbPath
        |> Cmd.arg ".mode json"
        |> Cmd.arg (janEvents |> List.map eventToInsert |> List.walk "" Str.concat)
        |> Cmd.status
        |> Task.attempt

    when result is
        Ok {} ->
            Stdout.line "write to db successfull."

        Err _ ->
            Stderr.line "Error while writing to db"

Event : {
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    startsAt : U128,
    endsAt : U128,
}

eventToInsert : Event -> Str
eventToInsert = \{ slug, title, location, description, startsAt, endsAt } ->
    "INSERT INTO events (slug, title, location, description, startsAt, endsAt, public) VALUES (\"\(slug)\", \"\(title)\", \"\(location)\", \"\(description)\", \(Num.toStr startsAt), \(Num.toStr endsAt), \(Num.toStr 1));"

janEvents : List Event
janEvents = [
    {
        slug: "2024-01-13-wcs-open-end-party",
        title: "WCS Open End Party",
        location: "Tanzschule Heiko Stender, Tibarg 40, Hamburg",
        description:
        """
        Wir freuen uns, wieder eine West Coast Swing Party in unserer Tanzschule ankündigen zu können und hoffen sehr, ganz viele alte und neue Gesichter zu sehen.

        Meldet euch gerne vorab an!
        Eintritt Party: 6 EUR
        """,
        startsAt: 1705172400,
        endsAt: 1705186740,
    },
    {
        slug: "2024-01-14-social-sunday-mit-schnupperkurs",
        title: "Social Sunday mit Schnupperkurs",
        location: "Tanzwerkstatt Hamburg-Eimsbüttel, Hoheluftchaussee 108, Hamburg",
        description:
        """
        SOCIAL SUNDAY - Die West Coast Swing Party am Sonntag! Was? Wir starten mit einem Schnupperkurs für alle, die Lust haben, diesen lässig-modernen Tanz kennenzulernen. 

        Wer? Du! Komm' alleine, zu zweit, oder bring' gleich alle Freund*innen mit - jeder ist willkommen! 

        KEINE VORANMELDUNG NÖTIG 

        17:00 Uhr - 18:00 Uhr -> Schnupperkurs
        18:00 Uhr - Open End -> Party
        Eintritt? 8,- € (inkl. Schnupperkurs)
        """,
        startsAt: 1705248000,
        endsAt: 1705273140,
    },
    {
        slug: "2024-01-26-last-friday-swing",
        title: "Last Friday Swing",
        location: "Hamburg Dance Academy, Stader Str. 2-4, Hamburg",
        description:
        """
        Unsere Tanznacht 'Last Friday Swing' ist Hamburgs erstes monatliches Event für 'West Coast Swing' und 'Discofox Slow' im südlichen Teil von Hamburg (Harburg). Unser Ziel ist es, eine gemeinsame Plattform für beide Tanzwelten zu schaffen und eine neue Heimat zu etablieren.

        Einlass: ab 21:00 Uhr
        Beginn: 21:30 Uhr Eröffnung
        Festes Ende: 01:30 Uhr
        """,
        startsAt: 1706299200,
        endsAt: 1706315400,
    },
]
