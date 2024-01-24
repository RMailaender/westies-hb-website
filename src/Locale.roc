interface Locale
    exposes [
        toLowerCase,
    ]
    imports [

    ]

toLowerCase : Str -> Str
toLowerCase = \input ->
    result =
        input
        |> Str.toUtf8
        |> List.map toLowerChar
        |> Str.fromUtf8

    when result is
        Ok str -> str
        Err _ -> crash "This should not be reachable"

expect
    input = "hElLoPe WORld! The answer 1S 42. ?"
    actual = toLowerCase input
    expected = "hellope world! the answer 1s 42. ?"

    actual == expected

toLowerChar : U8 -> U8
toLowerChar = \input ->
    when input is
        'A' -> 'a'
        'B' -> 'b'
        'C' -> 'c'
        'D' -> 'd'
        'E' -> 'e'
        'F' -> 'f'
        'G' -> 'g'
        'H' -> 'h'
        'I' -> 'i'
        'J' -> 'j'
        'K' -> 'k'
        'L' -> 'l'
        'M' -> 'm'
        'N' -> 'n'
        'O' -> 'o'
        'P' -> 'p'
        'Q' -> 'q'
        'R' -> 'r'
        'S' -> 's'
        'T' -> 't'
        'U' -> 'u'
        'V' -> 'v'
        'W' -> 'w'
        'X' -> 'x'
        'Y' -> 'y'
        'Z' -> 'z'
        _ -> input

toUpperCase : Str -> Str
toUpperCase = \input ->
    result =
        input
        |> Str.toUtf8
        |> List.map toUpperChar
        |> Str.fromUtf8

    when result is
        Ok str -> str
        Err _ -> crash "This should not be reachable"

expect
    input = "hElLoPe WORld! The answer 1S 42. ?"
    actual = toUpperCase input
    expected = "HELLOPE WORLD! THE ANSWER 1S 42. ?"

    actual == expected

toUpperChar : U8 -> U8
toUpperChar = \input ->
    when input is
        'a' -> 'A'
        'b' -> 'B'
        'c' -> 'C'
        'd' -> 'D'
        'e' -> 'E'
        'f' -> 'F'
        'g' -> 'G'
        'h' -> 'H'
        'i' -> 'I'
        'j' -> 'J'
        'k' -> 'K'
        'l' -> 'L'
        'm' -> 'M'
        'n' -> 'N'
        'o' -> 'O'
        'p' -> 'P'
        'q' -> 'Q'
        'r' -> 'R'
        's' -> 'S'
        't' -> 'T'
        'u' -> 'U'
        'v' -> 'V'
        'w' -> 'W'
        'x' -> 'X'
        'y' -> 'Y'
        'z' -> 'Z'
        _ -> input
