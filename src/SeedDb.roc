app "seed-db"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.7.1/Icc3xJoIixF3hCcfXrDwLCu4wQHtNdPyoJkEbkgIElA.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.6.0/hJySbEhJV026DlVCHXGOZNOeoOl7468y9F9Buhj0J18.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Task.{ Task },
        Time,
        Locale,
    ]
    provides [main] to pf

cet : Time.Zone
cet = Time.customZone (After (60 * 60)) []

main : Task {} I32
main =
    events
    |> List.map eventDataToDbEvent
    |> List.walk "" eventToInsert
    |> Stdout.write

Event : {
    slug : Str,
    title : Str,
    location : Str,
    description : Str,
    startsAt : Time.Posix,
    endsAt : Time.Posix,
}

eventToInsert : Str, Event -> Str
eventToInsert = \prev, { slug, title, location, description, startsAt, endsAt } ->
    endsAtStr = Time.posixToSeconds endsAt |> Num.toStr
    startsAtStr = Time.posixToSeconds startsAt |> Num.toStr
    """
    $(prev)

    INSERT INTO events (
        slug, 
        title,
        location,
        description,
        startsAt,
        endsAt,
        public
    ) VALUES (
        \"$(slug)\",
        \"$(title)\",
        \"$(location)\",
        \"$(description)\",
        $(startsAtStr), 
        $(endsAtStr), 
        $(Num.toStr 1)
    );
    """

EventData : {
    title : Str,
    location : Str,
    description : Str,
    startsAt : Str,
    endsAt : Str,
}

dateTimeFromDateStr : Str -> Time.DateTime
dateTimeFromDateStr = \s -> 
    elem =
        when s |> Str.split " " is 
            [dateStr, timeStr] ->
                dateStr |> Str.split "-"
                |> List.concat (timeStr |> Str.split ":")
            
            _ -> crash "fuck"


    when elem |> List.mapTry Str.toU128 is 
        Ok ([year, month, day, hours, minutes]) -> 
            {
                year, month, day, hours, minutes, seconds: 0
            }

        _ -> crash "fuck"


# "2024-02-03 20:00"
expect 
    actual = 
        "2024-02-03 20:00"
        |> dateTimeFromDateStr
        |> Time.dateTimeToPosix cet
        |> Time.posixToSeconds

    expected =  
        { year: 2024, month: 2, day: 3, hours: 20, minutes: 0, seconds: 0 }
        |> Time.dateTimeToPosix cet
        |> Time.posixToSeconds

    actual == expected


monthWithPaddedZeros : U128 -> Str
monthWithPaddedZeros = \month ->
    monthStr = Num.toStr month
    if month < 10 then
        "0$(monthStr)"
    else
        monthStr

dayWithPaddedZeros : U128 -> Str
dayWithPaddedZeros = monthWithPaddedZeros

createSlug : Time.DateTime, Str -> Str
createSlug = \{ year, month, day}, title -> 
    dayStr = dayWithPaddedZeros day
    monthStr = monthWithPaddedZeros month
    dateStrings = ["$(Num.toStr year)", "$(monthStr)", "$(dayStr)"]
    titleStrings =
        title
        |> Str.replaceEach "!" ""
        |> Locale.toLowerCase
        |> Str.split " "
        |> List.dropIf \elem -> elem == ""
        
    dateStrings 
    |> List.concat titleStrings
    |> Str.joinWith "-"
    
expect
    dt = { year: 2024, month: 2, day: 3, hours: 20, minutes: 30, seconds: 0 }
    title = "WCS Open End Party"

    actual = createSlug dt title
    expected = "2024-02-03-wcs-open-end-party"

    actual == expected

eventDataToDbEvent : EventData -> Event 
eventDataToDbEvent = \dbEvent ->
    startsAtDt = 
        dbEvent.startsAt
        |> dateTimeFromDateStr 

    slug =
        startsAtDt
        |> createSlug dbEvent.title

    startsAt = 
        startsAtDt 
        |> Time.dateTimeToPosix cet 

    endsAt = 
        dbEvent.endsAt
        |> dateTimeFromDateStr
        |> Time.dateTimeToPosix cet 

    {
        slug,
        title: dbEvent.title,
        description: dbEvent.description,
        location: dbEvent.location,
        startsAt,
        endsAt,
    }

events : List EventData
events = [
    {
        title: "West Coast Swing Party mit Schnupperkurs für Neueinsteiger",
        location: "Elbe-Werkstätten, Südring 38, 22303 Hamburg",
        description:
        """
        West Coast Swing Party mit Schnupperkurs für Neueinsteiger
        """,
        startsAt: "2024-01-03 18:30",
        endsAt: "2024-01-03 21:45",
    },
    {
        title: "SOCIAL SUNDAY West Coast Swing - NEUE LOCATION!!!",
        location: "Tanzwerkstatt Hamburg, Eifflerstraße 1, 22769 Hamburg, Deutschland",
        description:
        """
        SOCIAL SUNDAY West Coast Swing - NEUE LOCATION!!!
        """,
        startsAt: "2024-01-14 17:00",
        endsAt: "2024-01-14 20:00",
    },
    {
        title: "Tanzabend West Coast Swing und Discofox Slow",
        location: "Hamburg Dance Academy, Stader Str. 2- 4, 21075, Hamburg",
        description:
        """
        Die Party geht bis 02:00 Uhr

        Unsere Tanznacht Last Friday Swing ist Hamburgs erstes monatliches Event für West Coast Swing und Discofox Slow im südlichen Teil von Hamburg (Harburg). Unser Ziel ist es, eine gemeinsame Plattform für beide Tanzwelten zu schaffen und eine neue Heimat zu etablieren.

        Damit Dein Besuch reibungslos verläuft, gibt es einige Dinge, die Du im Voraus wissen solltest. Wir glauben fest daran, dass die Fusion von West Coast Swing und Discofox Slow möglich ist, solange es einen festen musikalischen Rahmen gibt.

        Die Musik spielt hierbei eine entscheidende Rolle. Obwohl die beiden Szenen normalerweise unterschiedliche Musik bevorzugen, machen wir eine Ausnahme! Bei unserer Tanznacht Last Friday Swing hörst Du vorwiegend englische Titel – keine Schlagerparty. Die sorgfältig ausgewählte Musik ist vielseitig und perfekt für kreative Improvisationen geeignet – bei uns gibt es kein einfaches 4 on the floor sondern unsere Musik ist swing lastig.

        Unsere Musikauswahl umfasst sowohl langsame als auch schnellere Lieder, mit einem Tempo von etwa 100 bis 120 BPM. Sehr schnelle Lieder mit über 130 BPM wirst Du bei uns nicht finden.

        Falls der Begriff Discofox Slow neu für Dich ist, sei versichert, dass dieser Bereich innerhalb des Discofox stetig wächst und immer beliebter wird. Die Musik ist langsamer, die Bewegungen können fließender sein, und dank der vielfältigen Musik bieten sich zahlreiche Möglichkeiten für Improvisationen, Breaks und Stops. Dies verleiht dem Discofox eine völlig neue Dimension.

        Weitere Infos :

        https://www.hamburg-dance-academy.de/events/unsere-veranstaltungen/tanznacht-last-friday-swing.html
        """,
        startsAt: "2024-01-26 21:00",
        endsAt: "2024-01-27 2:00",
    },
    
    {
        title: "Anchor Saturday",
        location: "Tanzwerkstatt Hoheluft, Hoheluftchaussee 108, 20253 Hamburg",
        description:
        """
        Der West Coast Swing ANCHOR SATURDAY ist wieder da!

        Wann und Wo?

        Uhrzeit: 20 Uhr bis 2 Uhr Party

        Preis: 7 Euro

        Location: Tanzwerkstatt Hoheluft
        Hoheluftchaussee 108, 20253 Hamburg

        Die Tanzwerkstatt Hoheluft liegt direkt an der Kreuzung Gärtnerstraße / Hoheluftchaussee, genau zwischen Eimsbüttel und Eppendorf. Direkt am UKE. Bestens angebunden an die öffentlichen Verkehrsmittel.

        Ich freue mich riesig auf euch alle! Meldet euch gerne bei Fragen.
        Liebe Grüße
        Eure Francis
        """,
        startsAt: "2024-02-03 20:00",
        endsAt: "2024-02-04 02:00",
    },
    {
        title: "West Coast Swing Party mit Schnupperkurs für Neueinsteiger",
        location: "Elbe-Werkstätten, Südring 38, 22303 Hamburg",
        description:
        """
        Monatliche Übungsparty immer am ersten Mittwoch im Monat.

        Mitten Im Herzen von Hamburg (Nähe U-Bahn Borgweg).

        18:30 bis 19:30 -> Schnupperkurs für absolute Neueinsteiger ohne Vorkenntnisse
        19:30 bis 21:45 -> Party für jeden und alle.

        Eintritt 5,- pro Person (Party und/oder Workshop).

        Wir bieten damit Interessierten monatlich die Möglichkeit West Coast Swing einfach mal auszuprobieren.

        In der Folge bieten wir immer jeweils am Mittwoch, Kurse für Basic, Level 1 und Level 2 an.

        Es wird keinen Getränkeverkauf geben.
        Bitte gern selber mitbringen.
        """,
        startsAt: "2024-02-07 18:30",
        endsAt: "2024-02-07 21:45",
    },
    {
        title: "West Coast Swing Workshop mit Tommy und Melli Party in der Tanzarena City",
        location: "Tanzarena City, Wandschneiderstr. 6, 28195 Bremen",
        description:
        """
        BREMEN

        West Coast Swing Workshop mit Tommy und Melli + Party in der Tanzarena City
        
        Datum: 10. Februar 2024
        Ort: Tanzarena City, Wandschneiderstr. 6, 28195 Bremen
        www.facebook.com/Tanzarena
        
        Voraussetzungen: Sugar Push, Left Side Pass, Under Arm Turn
        
        Preis: 55,- Euro pro Person (inklusive 3 Workshops und Party)
        
        Die Party wird im Anschluss an die Workshops stattfinden, also bleib dabei und tanze die Nacht durch!
        
        Anmeldung: per E-Mail an daniel-hollwedel@web.de
        
        Wir freuen uns auf euch!
        
        Zeitplan:
        
        15:00 - 16:00 Workshop 1
        
        16:15 - 17:15 Workshop 2
        
        17:30 - 18:30 Workshop 3
        
        ab 20 Uhr Party
        """,
        startsAt: "2024-02-10 15:00",
        endsAt: "2024-02-10 23:59",
    },
    {
        title: "Mein Tanzstudio West Coast Swing Party",
        location: "Mein Tanzstudio, Rantzaustrasse 74b, 22041, Hamburg",
        description:
        """
        Die Mein Tanzstudio West Coast Swing Party.
        Jeden 3. Freitag im Monat!
        Gute Musik, tolle Community, die sich über Neuzugänge freut.
        Auch für Singles bestens geeignet.

        Eintrittspreis: 8€

        Wir freuen uns auf euch!
        """,
        startsAt: "2024-02-16 20:00",
        endsAt: "2024-02-16 23:59",
    },
    {
        title: "WCS All LvL Workshop und Open End Party",
        location: "Tanzschule Heiko Stender,Tibarg 40, 22459, Hamburg",
        description:
        """
        All LvL Workshop mit Nathalie(18:30 - 20:00)
        Grundvoraussetzung:
        - Sugar Push
        - Left Side Pass
        - Under Arm Turn
        - Wipe
        mit anschließender Party (20:00 - ? )

        Workshop 10€
        Workshop mit Party 15€
        Nur Party 6€

        Abendkasse ist möglich
        """,
        startsAt: "2024-02-17 18:30",
        endsAt: "2024-02-17 21:30",
    },
    {
        title: "Pre Party zum West Coast Swing Workshop Weekend mit Marc Heldt nur Teilnehmer des Workshops",
        location: "Monopol, Ostertorwall 43, Hameln, Germany",
        description:
        """
        Das XL West Coast Swing Weekend in Hameln.
        The One and Only Marc Heldt kommt zu uns in die Rattenfängerstadt.

        Gestartet wird am Freitag um 20:00 Uhr mit einer PRE Party in der Tanzschule bewegungsart (nur für Workshopteilnehmer)

        Ab Samstag schwingen wir dann über den Dächern der Stadt unsere Hüften.
        """,
        startsAt: "2024-02-23 20:00",
        endsAt: "2024-02-23 23:59",
    },

]
