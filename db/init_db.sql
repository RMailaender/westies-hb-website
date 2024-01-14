CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    slug TEXT NOT NULL,
    title TEXT NOT NULL,
    location TEXT NOT NULL,
    description TEXT,
    startsAt INTEGER NOT NULL,
    endsAt INTEGER NOT NULL,
    public INTEGER NOT NULL
);

INSERT INTO events VALUES(1,'2024-01-13-wcs-open-end-party','WCS Open End Party','Tanzschule Heiko Stender, Tibarg 40, Hamburg',replace('Wir freuen uns, wieder eine West Coast Swing Party in unserer Tanzschule ankündigen zu können und hoffen sehr, ganz viele alte und neue Gesichter zu sehen.\n\nMeldet euch gerne vorab an!\nEintritt Party: 6 EUR','\n',char(10)),1705172400,1705186740,1);
INSERT INTO events VALUES(2,'2024-01-14-social-sunday-mit-schnupperkurs','Social Sunday mit Schnupperkurs','Tanzwerkstatt Hamburg-Eimsbüttel, Hoheluftchaussee 108, Hamburg',replace('SOCIAL SUNDAY - Die West Coast Swing Party am Sonntag! Was? Wir starten mit einem Schnupperkurs für alle, die Lust haben, diesen lässig-modernen Tanz kennenzulernen. \n\nWer? Du! Komm'' alleine, zu zweit, oder bring'' gleich alle Freund*innen mit - jeder ist willkommen! \n\nKEINE VORANMELDUNG NÖTIG \n\n17:00 Uhr - 18:00 Uhr -> Schnupperkurs\n18:00 Uhr - Open End -> Party\nEintritt? 8,- € (inkl. Schnupperkurs)','\n',char(10)),1705248000,1705273140,1);
INSERT INTO events VALUES(5,'2024-01-26-last-friday-swing','Last Friday Swing','Hamburg Dance Academy, Stader Str. 2-4, Hamburg',replace('Unsere Tanznacht ''Last Friday Swing'' ist Hamburgs erstes monatliches Event für ''West Coast Swing'' und ''Discofox Slow'' im südlichen Teil von Hamburg (Harburg). Unser Ziel ist es, eine gemeinsame Plattform für beide Tanzwelten zu schaffen und eine neue Heimat zu etablieren.\n\nEinlass: ab 21:00 Uhr\nBeginn: 21:30 Uhr Eröffnung\nFestes Ende: 01:30 Uhr','\n',char(10)),1706299200,1706315400,1);
