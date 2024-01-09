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

