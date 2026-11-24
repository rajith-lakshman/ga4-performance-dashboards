# Data dictionary

All files are aggregated daily counts. There are no user-level rows, no client IDs, no IP addresses, and no page paths or URLs (the path is reduced to a site language before saving).

| Folder | Contents |
|---|---|
| `demo/` | SYNTHETIC random data so the dashboard runs without credentials. It says nothing about any real website. |
| `real/` | Real archive written by `R/ga4_pull.R`. Empty until the first pull. |

## ga4_daily_views.csv
| Column | Meaning |
|---|---|
| `date` | Day (GA4 property time zone) |
| `language` | Site language from the URL's first folder: `en`, `si`, `ta`, or `other` |
| `country_id` | ISO 3166-1 alpha-2 code from GA4; `ZZ` = suppressed small cells; `(not set)` = unknown |
| `country` | Country name from GA4 |
| `views` | Page views (`screenPageViews`) |

Small-cell suppression: any date, language and country cell with fewer than 5 views is merged into `ZZ` / "Other (suppressed)".

## ga4_language_switches.csv
| Column | Meaning |
|---|---|
| `date` | Day |
| `from_language`, `to_language` | Language of the page the visitor was on, and the language they switched to |
| `switches` | Number of `language_switch` events |

Switch data only exists from the day the GTM tag and GA4 custom dimensions are live. It is not back-filled.

## page-inventory.csv
A lookup table of the 59 pages on the site (English, Sinhala and Tamil): `page path`, `language`, `section`, `content_type`, and technical flags (`includes_form`, `uses_query_strings`, `third_party_embeds`, `notes`). It holds no traffic data. Its `language`, `section` and `content_type` values are the ones the data layer snippet in `../gtm-datalayer.md` produces.
