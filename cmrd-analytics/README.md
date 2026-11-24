# Website analytics dashboard (GA4 + GTM + R)

A small, self-contained project: collect web analytics for a trilingual (English, Sinhala, Tamil) research-centre website with Google Tag Manager (GTM) and Google Analytics 4 (GA4), archive the aggregated data locally, and report it in an R / Quarto dashboard.

Built for the Centre for Migration Research and Development (CMRD), Sri Lanka, with its agreement to be named.

The dashboard shows:
1. Daily page views as a stacked area chart, by site language.
2. A world map of page views by country.
3. A 3 x 3 heat map of language switches (from row, to column).

A rendered copy is in [`docs/cmrd-dashboard.html`](../docs/cmrd-dashboard.html).

Screenshots of this dashboard and of a Looker Studio report on the same GA4 property (22 to 24 November 2026) are in the [root README](../README.md#evidence-that-the-cmrd-tracking-works): `docs/images/cmrd-R-dashboard.png` and `docs/images/cmrd-datastudio-dashboard.png`.

## Quick start (no credentials)
```r
# from this folder
quarto::quarto_render("dashboard.qmd")
```
The dashboard uses `data/cmrd/real/` when it has rows, otherwise `data/cmrd/demo/` (synthetic, labelled on the dashboard). The language-switch heat map shows "Not tracked yet" until switch rows exist.

## R packages
```r
install.packages(c("rnaturalearth", "rnaturalearthdata", "quarto"))
# also used (usually already installed): dplyr, tidyr, readr, ggplot2, sf, scales, knitr
```
Quarto itself (the command-line tool) is also needed: https://quarto.org/docs/get-started/ (Positron bundles it).

## How the real data is produced (private pull script)
The script that pulls the real data is not in this public repository. It lives in the private repository for the CMRD site, because it handles API access to CMRD's GA4 property. In outline, it:
1. Authenticates to the Google Analytics Data API with a service account that has Viewer access to the GA4 property. The key stays outside any repository.
2. Requests aggregated daily page views by page path and country, and the `language_switch` event count by `from_language` and `to_language`.
3. Reduces the page path to a language code (`en`, `si`, `ta` or `other`) and discards the path, so URLs are never stored.
4. Merges small cells (under 5 views a day) into "Other (suppressed)".
5. Drops switch rows whose languages are unset or invalid, and appends the results to the CSV files in `data/cmrd/real/`. It re-fetches the last 3 days each time because GA4 revises recent data.

The CSV archive outlives GA4's event-level retention (maximum 14 months). The files this dashboard reads, and their columns, are described in `data/cmrd/README.md`. The synthetic files in `data/cmrd/demo/` use the same layout.

## Privacy
- Only aggregated daily counts are stored (see `data/cmrd/README.md`). No user-level data, no client IDs, no IP addresses, no URLs.
- The page path is reduced to a language code before saving, so personal names in URLs are never stored.
- Country cells under 5 views a day are merged into "Other (suppressed)".
- Credentials (`.Renviron`, `*.json` keys) are git-ignored. Never commit them.

## How GA4 and GTM are used, in simple terms
- **GA4** is the place where measurements are stored and reported. It records page views, country, device and so on, and it is the source for the data pulled here.
- **GTM** is a control panel that sits on the website. The site loads GTM once; inside GTM you decide which measurements are sent to GA4 and when, without editing the website files each time. GTM has version history, a Preview mode for testing, and a way to roll back.

| Question | GA4 alone | Needs GTM (or extra website code) |
|---|---|---|
| Page views, countries, devices | Yes, automatic | |
| Which language section was viewed | Yes, from the page path (as done here) | |
| File downloads, outbound clicks | Yes, via GA4 "enhanced measurement" | |
| **Did the visitor switch language, and from which to which?** | **No** | **Yes** |
| Clicks on email or phone links | No | Yes |
| Scroll depth at 25 / 50 / 75% | Only 90% | Yes |
| Change tracking without redeploying the website | No | Yes |

Language switching is the clearest case. A language link is just an ordinary link to another page, so GA4 records a normal page view and has no notion that the visitor switched. A custom event has to be created. GTM can do that without code, by listening for clicks on the language links. In principle the same event could be written by hand into the website code, but then every change means editing and uploading files; with GTM it is changed in the GTM panel and tested in Preview first.

## Building the `language_switch` event in GTM
1. **Variables.** Use the built-in Click URL and Click Classes variables. Create a Data Layer Variable `language` (the site pushes `language`, `section`, `content_type` to the dataLayer on every page). Create a RegEx Table variable on Click URL that maps `^https?://[^/]+/en/` to `en`, `/si/` to `si`, and `/ta/` to `ta`.
2. **Trigger.** Click, Just Links. Condition: Click URL matches RegEx `^https?://[^/]+/(en|si|ta)/` and Click Classes contains `w3-right` (the class on the language links). Check in Preview that ordinary menu links do not fire it; if they do, ask the site manager to add a dedicated class such as `lang-switch` to the language links and use that instead.
3. **Tag.** GA4 Event tag using the existing Google tag. Event name `language_switch`. Parameters: `from_language` = the Data Layer Variable, `to_language` = the RegEx Table variable.
4. **GA4.** Admin > Custom definitions: create two event-scoped custom dimensions, `from_language` and `to_language`. Data only appears after this, and it is not back-filled.
5. Test in GTM Preview and GA4 DebugView, then publish a new container version with a version note.

Use built-in GTM tag and variable types only (no Custom HTML tags).

## Limitations
- Counts only cover visitors whose browsers send data; consent choices, ad blockers and device settings reduce coverage.
- Content differs by language (English is complete; Sinhala and Tamil are partial), so language comparisons are not like for like.
- GA4 can adjust recent days; the pull script re-fetches the last 3 days.

## Status and known limits
- The page-views pull has been run against a live GA4 property. Real data starts on 2026-11-22, so it is only a few days long.
- `language_switch` data exists only from the day the GTM tag and GA4 custom dimensions went live. Events recorded before the dimensions were registered show as `(not set)` and are dropped by the pull script. New custom dimensions can take up to 24 hours to appear in the API.
- Early real data includes the site manager's own test visits (no internal-traffic filter yet), so treat it as a demonstration, not as a picture of the audience.
- If `data/cmrd/real/` has view rows but no switch file, the heat map is empty; it does not fall back to demo data.

## Adapting to another site
- Language is read from the first folder of the page path (`/en/`, `/si/`, `/ta/`). Change `SITE_LANGUAGES` (set at the top of `dashboard.qmd`) and the path-to-language step in the pull script for other URL schemes.
- The GTM trigger in this project uses the `w3-right` CSS class to find language links. Another site needs its own selector, ideally a dedicated class.

## Files
| Path | Purpose |
|---|---|
| `dashboard.qmd` | Quarto dashboard |
| `styles.css` | Small style tweak for the dashboard |
| `data/cmrd/real/` | Real aggregated GA4 data (a few days so far) |
| `data/cmrd/demo/` | Synthetic demo data in the same layout |
| `data/cmrd/page-inventory.csv` | The 59 CMRD pages with language, section and content type (a lookup table, no traffic) |
| `data/cmrd/README.md` | Data dictionary |
| `gtm-datalayer.md` | The page header snippet that pushes language, section and content type to the data layer |

Not included: the private pull script and its helpers (see above), and the synthetic data generator.
