# JD Movies for iOS

The iOS companion to the [JD Movies](https://jd-movies.netlify.app) website: browse every movie Johnathan has rated, filter by genre, universe, director, streaming provider and more, see what's playing in theatres, get a random pick, open any actor or director's filmography, and explore stats across the whole catalogue.

Built with SwiftUI, Swift Concurrency, Observation and Swift Charts. No third-party dependencies. Movie data comes from the ratings API, with posters, provider availability and theatre listings from [TMDB](https://www.themoviedb.org/) and [JustWatch](https://www.justwatch.com/).

## Requirements

- Xcode 26 and iOS 26.
- A TMDB v3 API key (optional, see below).

## Setup

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
# edit Config/Secrets.xcconfig and set JD_TMDB_API_KEY
open "JD Movies.xcodeproj"
```

`Config/Secrets.xcconfig` is git-ignored. Without a key the app still works; the home screen just omits the theatre rows and unrated movies and person bios have no TMDB fallback.

| Setting                   | Where                   | Purpose                                  |
| ------------------------- | ----------------------- | ---------------------------------------- |
| `JD_RATINGS_API_BASE_URL` | `Config/App.xcconfig`   | Base URL of the ratings API              |
| `JD_SITE_BASE_URL`        | `Config/App.xcconfig`   | Website URL, used for share links        |
| `JD_TMDB_API_KEY`         | `Config/Secrets.xcconfig` | TMDB v3 API key                        |

These flow into `Config/Info.plist` at build time and are read once by `AppConfiguration`.

## Layout

```
JD Movies/
  App/           entry point, tab bar, routes, environment, configuration
  Core/          platform-independent models, networking and business logic
    Models/      Codable API types (Movie, CompactMovie, FilterTypes, TMDB)
    Networking/  HTTPClient, ratings API client, TMDB client
    Logic/       home rows, stats, search index, filters, score gradient
    Data/        MovieRepository: caching, de-duplication, TMDB fallback
    Fixtures/    test data and stub services (DEBUG only)
  Data/          image loading and caching
  Features/      one folder per screen: view + view model
  Shared/        theme, poster tiles, charts helpers, reusable controls
JD MoviesTests/  Swift Testing unit tests for Core
Config/          xcconfig files and Info.plist
```

## Architecture

- **Core is UI-free.** Everything under `Core/` imports only Foundation and is marked `nonisolated`, so it compiles and runs on any platform. The business logic mirrors the website's `homeRows.ts`, `stats.ts`, `utils.ts` and `providerSearch.ts` one to one.
- **One repository.** `MovieRepository` is an actor that wraps both APIs, caches results with short TTLs (matching the site's ISR intervals), coalesces concurrent requests and implements the "404 falls back to TMDB" rule for unrated movies.
- **View models are `@Observable` and main-actor.** Each screen owns one; views render a `Loadable` state and never touch the network directly.
- **Navigation is value-based.** `Route` (movie, person, grid) is pushed with `NavigationLink(value:)` and resolved once per tab stack.
- **Theme.** The website's dark stone palette, yellow accent and red-to-green score gradient are reproduced in `Shared/Theme.swift`; the gradient table is generated from the site's `gradient.ts`.

## Tests

Run the `JD MoviesTests` scheme in Xcode (⌘U). The tests cover the home rows, stats aggregation, search, filter conversion, provider deep links, JSON decoding of the Go API's `null` lists, and the repository's fallback and caching behaviour.
