app "westies-hb-server"
    packages {
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.1/dCL3KsovvV-8A5D_W_0X_abynkcRcoAngsgF0xtvQsk.tar.br",
        html: "https://github.com/Hasnep/roc-html/releases/download/v0.2.0/5fqQTpMYIZkigkDa2rfTc92wt-P_lsa76JVXb8Qb3ms.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        pf.Utc,
        html.Html,
    ]
    provides [main] to pf

main : Request -> Task Response []
main = \req ->
    res = Html.html [] [
        Html.body [] [
            Html.h1 [] [Html.text "Epic Hacking Website"],
            Html.p [] [
                Html.text "Here's some sneaky JavaScript code to hack your computer:",
                Html.text "<script>alert('You have been hacked!')</script>",
            ],
        ],
    ] |> Html.render

    date <- Utc.now |> Task.map Utc.toIso8601Str |> Task.await
    {} <- Stdout.line "\(date) \(Http.methodToStr req.method) \(req.url)" |> Task.await

    # Respond with request body
    when req.body is
        EmptyBody -> Task.ok { status: 200, headers: [], body: Str.toUtf8 "hello there" }
        Body _ -> Task.ok { status: 200, headers: [], body: Str.toUtf8 res }
