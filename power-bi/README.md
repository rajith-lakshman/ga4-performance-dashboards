# Power BI project

Semantic model for the same KPIs as the R and Python dashboards. It reads the CSVs in `data/GA4-demo/` (GA4 **sample data**). No credentials are used or stored.

Project format: PBIP. Schema versions found in the scaffold: `.pbip` 1.0, `definition.pbir` 4.0, `definition.pbism` 4.2, report `version.json` 2.0.0, report 3.3.0, page 2.1.0, model compatibilityLevel 1606.

## What is in the model

| Table | Source | Notes |
|---|---|---|
| `daily_kpis`, `channel_summary`, `device_summary`, `funnel_daily` | `data/GA4-demo/*.csv` | Columns exactly as in the data contract (`docs/dashboard-spec.md`) |
| `Date`, `Month` | Calculated | Date table for daily tables; month table for channel and device. `Date[In funnel window]` is hard-coded to 2020-11-25 onward (update it if the data is refreshed) |

Relationships (many-to-one, single direction): `daily_kpis.date` and `funnel_daily.date` to `Date.Date`; `channel_summary.month` and `device_summary.month` to `Month.Month`.

Measures (display folders in brackets): Total sessions, Engaged sessions, Engagement rate, Daily active users, New users, Returning users, New user share, Returning user share (Overview, Audience); Channel sessions, Channel share (Channel); Device sessions, Device share (Device); Funnel sessions, Step drop-off (Funnel). Each has a format string and description.

## Open the project and set DataFolder

1. Close Power BI Desktop completely if it is open, then double-click `power-bi/GA4demo.pbip` (or File > Open report > Browse this device).
2. Home > Transform data > Edit parameters. Set `DataFolder` to the full path of your `data/GA4-demo` folder, for example `C:\path\to\ga4-performance-dashboards\data\sample`. Click OK, then Apply changes.
3. Refresh from Home > Refresh. Re-run after replacing any CSV.

If Desktop prompts about project files or previews, accept. If the project does not open, see the fallback below.

## Report pages

Three PBIR pages (20 visuals), each titled with the question it answers, with a SAMPLE DATA text box and a footnote text box (KPI definitions and limitations):

| Page | Visuals |
|---|---|
| How many sessions did the site get, and how engaged were they? | 3 cards, 2 line charts |
| Who visited: new or returning users, which channels and devices? | 2 cards, 2 bar charts |
| Where do sessions drop out between viewing an item and purchasing? | funnel, step drop-off bar chart |

Every card and chart has alt text and a title. Series use the Okabe-Ito blue (#0072B2) and bar and funnel values are labelled.

Written against visual container schema 2.13.0. The schema defines the container and field references; the visual role names (`Values`, `Category`, `Y`), the text box paragraph format, alt text, data point colour, labels and the sort definition on the drop-off chart follow PBIR conventions that the schema does not validate, so check them when you first open the report. The custom accessible theme was not added, so non-chart elements use the default theme.

## Known issues and caveats

- **Tested in Power BI Desktop (October 2026 release, 2.159).** The project opens with no errors. Desktop re-saves the files on save, adding `lineageTag` values; that is expected. If a later release rejects the model, Desktop shows the file and line.
- Saving in Desktop rewrites `expressions.tmdl` with your own folder path. Before committing, restore the placeholder: `git checkout -- power-bi/GA4demo.SemanticModel/definition/expressions.tmdl` (the pre-commit hook also blocks personal paths).
- `.pbi/localSettings.json` and `.pbi/cache.abf` are git-ignored; cache.abf may hold an earlier model's data. Delete it locally if unwanted.
- New/returning user measures and shares are sums of daily distinct counts (user-days), not distinct users.
- `Date[In funnel window]` is hard-coded; the funnel measures use it.

## Fallback: plain DAX

If the project will not open, create a blank report, import the five CSVs, and paste each measure from `definition/tables/*.tmdl` (the line after `measure`) into New measure.

## Screenshots

Used by the root `README.md`. Save them in `docs/images/` with these exact names:

| File | What to capture |
|---|---|
| `powerbi-1-overview.png` | Overview page, whole page visible |
| `powerbi-2-audience.png` | Audience page |
| `powerbi-3-funnel.png` | Funnel page |
| `powerbi-model.png` | Model view (tables, four relationships) |

How: View > Page view > Fit to page, then capture the report canvas only with Windows Snipping Tool (Win+Shift+S) and save as PNG. Before saving, check that each image shows:

- [ ] the page title (the question), the SAMPLE DATA banner and the footnote
- [ ] no browser or Desktop sign-in name, no file paths (the `DataFolder` value, the title bar path) and no other personal details
- [ ] a width of about 1600 to 1920 px, so text is readable

Optional extras: the alt text pane and the Edit parameters dialog (blur the path).
