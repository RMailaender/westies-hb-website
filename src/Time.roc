interface Time
    exposes [
        DateTime,
        Posix,
        Zone,
        dateTimeToPosix,
        posixFromMillis,
        sameMonth,
        gtEqMonth,
        posixFromNanos,
        posixFromSeconds,
        toIso8601Str,
        customZone,
        posixToNanos,
        posixToMillis,
        posixToSeconds,
        posixToMinutes,
        toDateTime,
        TimeOffset,
        displayDt,
    ]
    imports [
    ]

Posix := U128

Zone := { offset : TimeOffset, eras : List Era }

TimeOffset : [
    Before U128,
    After U128,
]

Era : { start : U128, offset : TimeOffset }

DateTime : { year : U128, month : U128, day : U128, hours : U128, minutes : U128, seconds : U128 }

displayDt : DateTime -> Str
displayDt = \dt -> "$(Num.toStr dt.day).$(Num.toStr dt.month).$(Num.toStr dt.year) :: $(Num.toStr dt.hours):$(Num.toStr dt.minutes):$(Num.toStr dt.seconds)"

eq : Posix, Posix -> Bool
eq = \@Posix a, @Posix b ->
    (a) == (b)

gt : Posix, Posix -> Bool
gt = \@Posix a, @Posix b ->
    (a) > (b)

lt : Posix, Posix -> Bool
lt = \@Posix a, @Posix b ->
    (a) < (b)

compare : Posix, Posix -> [LT, EQ, GT]
compare = \a, b ->
    if eq a b then
        EQ
    else if lt a b then
        LT
    else
        GT

gtEqMonth : Posix, Posix, Zone -> Bool
gtEqMonth = \x, reference, zone ->
    xDt = toDateTime x zone
    refDt = toDateTime reference zone

    (xDt.year > refDt.year)
    ||
    ((xDt.year == refDt.year) && (xDt.month >= refDt.month))

expect
    cet = Time.customZone (After (60 * 60)) []
    # 2024-02-08
    x = posixFromSeconds 1707415200
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    gtEqMonth x ref cet == Bool.true

expect
    cet = Time.customZone (After (60 * 60)) []
    # 2025-01-06
    x = posixFromSeconds 1736186400
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    gtEqMonth x ref cet == Bool.true

expect
    cet = Time.customZone (After (60 * 60)) []
    # 2024-01-10
    x = posixFromSeconds 1704909600
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    gtEqMonth x ref cet == Bool.false

expect
    cet = Time.customZone (After (60 * 60)) []
    # 2023-03-02
    x = posixFromSeconds 1677780000
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    gtEqMonth x ref cet == Bool.false

sameMonth : Posix, Posix, Zone -> Bool
sameMonth = \x, reference, zone ->
    xDt = toDateTime x zone
    refDt = toDateTime reference zone

    ((xDt.year == refDt.year) && (xDt.month == refDt.month))

# Same month
expect
    cet = Time.customZone (After (60 * 60)) []
    # 2024-02-08
    x = posixFromSeconds 1707415200
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    sameMonth x ref cet == Bool.true

# Some time before
expect
    cet = Time.customZone (After (60 * 60)) []
    # 2023-03-02
    x = posixFromSeconds 1677780000
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    sameMonth x ref cet == Bool.false

# same month next year
expect
    cet = Time.customZone (After (60 * 60)) []
    # 2025-02-05
    x = posixFromSeconds 1738778400
    # 2024-02-20
    ref = posixFromSeconds 1708452000

    sameMonth x ref cet == Bool.false

nanosPerMilli = 1_000_000
millisPerSecond = 1_000
secondsPerMinute = 60
minutesPerHour = 60
hoursPerDay = 24
daysPerWeek = 7

posixFromNanos : U128 -> Posix
posixFromNanos = \nanos -> @Posix nanos

posixFromMillis : U128 -> Posix
posixFromMillis = \millis ->
    (millis * nanosPerMilli)
    |> posixFromNanos

posixFromSeconds : U128 -> Posix
posixFromSeconds = \seconds ->
    (seconds * millisPerSecond)
    |> posixFromMillis

posixToNanos : Posix -> U128
posixToNanos = \@Posix nanos -> nanos

posixToMillis : Posix -> U128
posixToMillis = \time ->
    posixToNanos time
    |> Num.divTrunc nanosPerMilli

posixToSeconds : Posix -> U128
posixToSeconds = \time ->
    posixToMillis time
    |> Num.divTrunc millisPerSecond

posixToMinutes : Posix -> U128
posixToMinutes = \time ->
    posixToSeconds time
    |> Num.divTrunc secondsPerMinute

customZone : TimeOffset, List Era -> Zone
customZone = \offset, eras ->
    @Zone { offset, eras }

toIso8601Str : DateTime -> Str
toIso8601Str = \{ year, month, day, hours, minutes, seconds } ->
    yearStr = yearWithPaddedZeros year
    monthStr = monthWithPaddedZeros month
    dayStr = dayWithPaddedZeros day
    hourStr = hoursWithPaddedZeros hours
    minuteStr = minutesWithPaddedZeros minutes
    secondsStr = secondsWithPaddedZeros seconds

    "\(yearStr)-\(monthStr)-\(dayStr)T\(hourStr):\(minuteStr).\(secondsStr)Z"

yearWithPaddedZeros : U128 -> Str
yearWithPaddedZeros = \year ->
    yearStr = Num.toStr year
    if year < 10 then
        "000\(yearStr)"
    else if year < 100 then
        "00\(yearStr)"
    else if year < 1000 then
        "0\(yearStr)"
    else
        yearStr

monthWithPaddedZeros : U128 -> Str
monthWithPaddedZeros = \month ->
    monthStr = Num.toStr month
    if month < 10 then
        "0\(monthStr)"
    else
        monthStr

dayWithPaddedZeros : U128 -> Str
dayWithPaddedZeros = monthWithPaddedZeros

hoursWithPaddedZeros : U128 -> Str
hoursWithPaddedZeros = monthWithPaddedZeros

minutesWithPaddedZeros : U128 -> Str
minutesWithPaddedZeros = monthWithPaddedZeros

secondsWithPaddedZeros : U128 -> Str
secondsWithPaddedZeros = monthWithPaddedZeros

isLeapYear : U128 -> Bool
isLeapYear = \year ->
    (year % 4 == 0)
    && # divided evenly by 4 unless...
    (
        (year % 100 != 0)
        || # divided by 100 not a leap year
        (year % 400 == 0) # expecpt when also divisible by 400
    )

expect isLeapYear 2000
expect isLeapYear 2012
expect !(isLeapYear 1900)
expect !(isLeapYear 2015)
expect List.map [2023, 1988, 1992, 1996] isLeapYear == [Bool.false, Bool.true, Bool.true, Bool.true]
expect List.map [1700, 1800, 1900, 2100, 2200, 2300, 2500, 2600] isLeapYear == [Bool.false, Bool.false, Bool.false, Bool.false, Bool.false, Bool.false, Bool.false, Bool.false]

daysInMonth : U128, U128 -> U128
daysInMonth = \month, year ->
    if List.contains [1, 3, 5, 7, 8, 10, 12] month then
        31
    else if List.contains [4, 6, 9, 11] month then
        30
    else if month == 2 then
        (if isLeapYear year then 29 else 28)
    else
        0

expect daysInMonth 1 2023 == 31 # January
expect daysInMonth 2 2023 == 28 # February
expect daysInMonth 2 1996 == 29 # February in a leap year
expect daysInMonth 3 2023 == 31 # March
expect daysInMonth 4 2023 == 30 # April
expect daysInMonth 5 2023 == 31 # May
expect daysInMonth 6 2023 == 30 # June
expect daysInMonth 7 2023 == 31 # July
expect daysInMonth 8 2023 == 31 # August
expect daysInMonth 9 2023 == 30 # September
expect daysInMonth 10 2023 == 31 # October
expect daysInMonth 11 2023 == 30 # November
expect daysInMonth 12 2023 == 31 # December

daysInYear : U128 -> U128
daysInYear = \year -> if isLeapYear year then 366 else 365

daysToSeconds : U128 -> U128
daysToSeconds = \d -> d * hoursPerDay * minutesPerHour * secondsPerMinute

expect
    actual = daysToSeconds 2
    expected = 172800

    actual == expected

dateTimeToPosix : DateTime, Zone -> Posix
dateTimeToPosix = \current, zone ->
    days = if current.day > 0 then current.day - 1 else 0
    months = if current.month > 0 then current.month - 1 else 0

    secondsCurrentMonth =
        current.seconds
        |> Num.add (current.minutes * secondsPerMinute)
        |> Num.add (current.hours * minutesPerHour * secondsPerMinute)
        |> Num.add (daysToSeconds days)

    secondsCurrentYear =
        List.range { start: At 1, end: Before current.month }
        |> List.map \month -> daysInMonth month current.year
        |> List.map daysToSeconds
        |> List.walk secondsCurrentMonth Num.add

    List.range { start: At 1970, end: Before current.year }
    |> List.map daysInYear
    |> List.map daysToSeconds
    |> List.walk secondsCurrentYear Num.add
    |> subtractOffsetFromSeconds zone
    |> posixFromSeconds

# 05/02/2025 17:55:55
expect
    utc = customZone (After 0) []
    actual =
        { year: 2025, month: 2, day: 5, hours: 17, minutes: 55, seconds: 55 }
        |> dateTimeToPosix utc
        |> posixToSeconds

    expected = 1738778155

    actual == expected

# 05/02/2025 17:55:55
expect
    cet = customZone (After (60 * 60)) []
    actual =
        { year: 2025, month: 2, day: 5, hours: 17, minutes: 55, seconds: 55 }
        |> dateTimeToPosix cet
        |> posixToSeconds

    expected = 1738774555

    actual == expected

# 01/02/2024 17:55:55
expect
    utc = customZone (After 0) []
    actual =
        { year: 2024, month: 2, day: 1, hours: 17, minutes: 55, seconds: 55 }
        |> dateTimeToPosix utc
        |> posixToSeconds

    expected = 1706810155

    actual == expected

# 01/01/2024 00:00:00
expect
    utc = customZone (After 0) []
    actual =
        { year: 2024, month: 1, day: 1, hours: 0, minutes: 0, seconds: 0 }
        |> dateTimeToPosix utc
        |> posixToSeconds

    expected = 1704067200

    actual == expected

toDateTime : Posix, Zone -> DateTime
toDateTime = \time, zone ->
    seconds = toAdjustedSeconds time zone
    minutes = Num.divTrunc seconds 60
    hours = Num.divTrunc minutes 60
    day = 1 + Num.divTrunc hours 24
    month = 1
    year = 1970

    epochMillisToDateTimeHelp {
        year,
        month,
        day,
        hours,
        minutes,
        seconds,
    }

toAdjustedSeconds : Posix, Zone -> U128
toAdjustedSeconds = \time, @Zone { offset, eras } ->
    posixSeconds = posixToSeconds time
    toAdjustedSecondsHelp offset posixSeconds eras

toAdjustedSecondsHelp : TimeOffset, U128, List Era -> U128
toAdjustedSecondsHelp = \defaultOffset, posixSeconds, eras ->
    when eras is
        [] ->
            applyOffsetToPosixSeconds posixSeconds defaultOffset

        [era, .. as olderEras] ->
            if era.start < posixSeconds then
                applyOffsetToPosixSeconds posixSeconds era.offset
            else
                toAdjustedSecondsHelp defaultOffset posixSeconds olderEras

subtractOffsetFromSeconds : U128, Zone -> U128
subtractOffsetFromSeconds = \posixSeconds, @Zone { offset, eras } ->
    subtractOffsetFromSecondsHelp offset posixSeconds eras

subtractOffsetFromSecondsHelp : TimeOffset, U128, List Era -> U128
subtractOffsetFromSecondsHelp = \defaultOffset, posixSeconds, eras ->
    when eras is
        [] ->
            applyReversedOffsetToPosixSeconds posixSeconds defaultOffset

        [era, .. as olderEras] ->
            if era.start < posixSeconds then
                applyReversedOffsetToPosixSeconds posixSeconds era.offset
            else
                subtractOffsetFromSecondsHelp defaultOffset posixSeconds olderEras

applyOffsetToPosixSeconds : U128, TimeOffset -> U128
applyOffsetToPosixSeconds = \posixSeconds, offset ->
    when offset is
        Before seconds ->
            posixSeconds - seconds

        After seconds ->
            posixSeconds + seconds

applyReversedOffsetToPosixSeconds : U128, TimeOffset -> U128
applyReversedOffsetToPosixSeconds = \posixSeconds, offset ->
    when offset is
        Before seconds ->
            posixSeconds + seconds

        After seconds ->
            posixSeconds - seconds

epochMillisToDateTimeHelp : DateTime -> DateTime
epochMillisToDateTimeHelp = \current ->

    countDaysInYear = if isLeapYear current.year then 366 else 365
    countDaysInMonth = daysInMonth current.month current.year

    if current.day >= countDaysInYear then
        epochMillisToDateTimeHelp {
            year: current.year + 1,
            month: current.month,
            day: current.day - countDaysInYear,
            hours: current.hours - (countDaysInYear * 24),
            minutes: current.minutes - (countDaysInYear * 24 * 60),
            seconds: current.seconds - (countDaysInYear * 24 * 60 * 60),
        }
    else if current.day >= countDaysInMonth then
        epochMillisToDateTimeHelp {
            year: current.year,
            month: current.month + 1,
            day: current.day - countDaysInMonth,
            hours: current.hours - (countDaysInMonth * 24),
            minutes: current.minutes - (countDaysInMonth * 24 * 60),
            seconds: current.seconds - (countDaysInMonth * 24 * 60 * 60),
        }
    else
        { current &
            hours: current.hours % 24,
            minutes: current.minutes % 60,
            seconds: current.seconds % 60,
        }

# test 1_700_005_179_053 ms past epoch
# expect
#     str = 1_700_005_179_053 |> posixFromMillis |> toIso8601Str
#     str == "2023-11-14T23:39.39Z"

# # test 1000 ms past epoch
# expect
#     str = 1_000 |> posixFromMillis |> toIso8601Str
#     str == "1970-01-01T00:00.01Z"

# # test 1_000_000 ms past epoch
# expect
#     str = 1_000_000 |> posixFromMillis |> toIso8601Str
#     str == "1970-01-01T00:16.40Z"

# # test 1_000_000_000 ms past epoch
# expect
#     str = 1_000_000_000 |> posixFromMillis |> toIso8601Str
#     str == "1970-01-12T13:46.40Z"

# # test 1_600_005_179_000 ms past epoch
# expect
#     str = 1_600_005_179_000 |> posixFromMillis |> toIso8601Str
#     str == "2020-09-13T13:52.59Z"

toWeekday : U128 -> Weekday
toWeekday = \millis ->
    minutes = divFloor millis 60_000
    r = divFloor minutes (60 * 24)
    when modBy 7 r is
        0 -> Thu
        1 -> Fri
        2 -> Sat
        3 -> Sun
        4 -> Mon
        5 -> Tue
        _ -> Wed

divFloor = \a, b ->
    Num.floor ((Num.toF64 a) / (Num.toF64 b))

modBy = \modulus, x ->
    answer = x % modulus
    if (answer > 0 && modulus < 0) || (answer < 0 && modulus > 0) then
        answer + modulus
    else
        answer

expect
    day = 1705941640_000 |> toWeekday
    day == Mon

expect
    day = 1705172400_000 |> toWeekday
    day == Sat

expect
    day = 1706299200_000 |> toWeekday
    day == Fri

expect
    minutes = divFloor 1705939200 60
    hours = divFloor (minutes) 60
    hour = modBy 24 hours
    hour == 16

expect
    minutes = divFloor 1705942800 60
    hours = divFloor (minutes) 60
    hour = modBy 24 hours
    hour == 17

# expect
#     r = (Num.rem 0 2)
#     r == 2

# expect
#     r = (Num.rem 1 2)
#     r == 1
# expect
#     r = (Num.rem 2 2)
#     r == 0

# =================================================
#   From Elm/time
# =================================================
Month : [
    Jan,
    Feb,
    Mar,
    Apr,
    May,
    Jun,
    Jul,
    Aug,
    Sep,
    Oct,
    Nov,
    Dec,
]

toGermanMonth : Month -> Str
toGermanMonth = \month ->
    when month is
        Jan -> "Januar"
        Feb -> "Februar"
        Mar -> "März"
        Apr -> "April"
        May -> "Mai"
        Jun -> "Juni"
        Jul -> "Juli"
        Aug -> "August"
        Sep -> "September"
        Oct -> "Oktober"
        Nov -> "November"
        Dec -> "Dezember"

toGermanMonthShort : Month -> Str
toGermanMonthShort = \month ->
    when month is
        Jan -> "Jan"
        Feb -> "Feb"
        Mar -> "Mrz"
        Apr -> "Apr"
        May -> "Mai"
        Jun -> "Jun"
        Jul -> "Jul"
        Aug -> "Aug"
        Sep -> "Sept"
        Oct -> "Okt"
        Nov -> "Nov"
        Dec -> "Dez"

Weekday : [
    Mon,
    Tue,
    Wed,
    Thu,
    Fri,
    Sat,
    Sun,
]

toGermanWeekday : Weekday -> Str
toGermanWeekday = \weekday ->
    when weekday is
        Mon -> "Mo"
        Tue -> "Di"
        Wed -> "Mi"
        Thu -> "Do"
        Fri -> "Fr"
        Sat -> "Sa"
        Sun -> "So"
