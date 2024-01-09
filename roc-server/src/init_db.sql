CREATE TABLE user (
    id INTEGER PRIMARY KEY ASC,
    name TEXT,
);

CREATE TABLE login_credentials (
    id INTEGER PRIMARY KEY ASC,
    email TEXT,
    password TEXT,
    user INTEGER,

    FOREIGN KEY (user) REFERENCES user(id)
);
