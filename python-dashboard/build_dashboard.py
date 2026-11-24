"""Build a static, self-contained HTML dashboard (docs/python-dashboard.html).

Reads only data/GA4-demo/. No login needed.
Requires: pandas, plotly (see requirements.txt).
"""
from html import escape
from pathlib import Path

import pandas as pd
import plotly.express as px
from plotly.offline import get_plotlyjs

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "data" / "GA4-demo"
OUT = ROOT / "docs" / "python-dashboard.html"

# Okabe-Ito colour-blind-safe palette
OKABE = ["#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9", "#D55E00", "#F0E442", "#999999"]

daily = pd.read_csv(SAMPLE / "daily_kpis.csv", parse_dates=["date"])
channel = pd.read_csv(SAMPLE / "channel_summary.csv", parse_dates=["month"])
device = pd.read_csv(SAMPLE / "device_summary.csv", parse_dates=["month"])
funnel = pd.read_csv(SAMPLE / "funnel_daily.csv", parse_dates=["date"])

# Funnel window starts the day after the last day with a missing funnel step
steps_per_day = daily["date"].map(funnel.groupby("date").size()).fillna(0)
funnel_start = daily.loc[steps_per_day < 4, "date"].max() + pd.Timedelta(days=1)
funnel_window = funnel[funnel["date"] >= funnel_start]


def style(fig, height=380):
    fig.update_layout(
        height=height, margin=dict(l=10, r=10, t=10, b=10), legend=dict(orientation="h", y=-0.2, title=None),
        template="simple_white", font=dict(size=13),
    )
    return fig


def figure_html(fig, alt):
    inner = fig.to_html(full_html=False, include_plotlyjs=False, config={"displaylogo": False})
    return f'<figure role="img" aria-label="{escape(alt)}">{inner}<figcaption class="sr">{escape(alt)}</figcaption></figure>'


def share_fig(df, category, value):
    d = df.copy()
    d["month_lbl"] = d["month"].dt.strftime("%b %Y")
    d["share"] = d[value] / d.groupby("month")[value].transform("sum")
    d["label"] = d["share"].map(lambda v: f"{v:.0%}" if v >= 0.04 else "")
    order = list(d.sort_values("month")["month_lbl"].unique())
    fig = px.bar(
        d, x="share", y="month_lbl", color=category, pattern_shape=category, orientation="h", text="label",
        color_discrete_sequence=OKABE, category_orders={"month_lbl": order},
        labels={"share": "Share", "month_lbl": "", category: ""},
    )
    fig.update_yaxes(autorange="reversed")
    fig.update_xaxes(tickformat=".0%", range=[0, 1])
    return style(fig, 300)


def card(title, body):
    return f'<section class="card"><h3>{escape(title)}</h3>{body}</section>'


def page(question, banner, cards, definitions, limitations):
    return (
        f'<section class="page"><h2>{escape(question)}</h2>' + (f'<p class="banner">{banner}</p>' if banner else '') +
        f'<div class="grid">{"".join(cards)}</div>'
        f'<p class="note"><strong>KPI definitions.</strong> {definitions}</p>'
        f'<p class="note"><strong>Limitations.</strong> {limitations}</p></section>'
    )


def kpis(items):
    return '<div class="kpis">' + "".join(
        f'<div class="kpi"><div class="v">{v}</div><div class="l">{escape(label)}</div></div>' for label, v in items
    ) + "</div>"


SAMPLE_BANNER = (
    "<strong>SAMPLE DATA.</strong> Google Merchandise Store GA4 sample ecommerce dataset (obfuscated), "
    "1 Nov 2020 to 31 Jan 2021. This is not CMRD traffic."
)

# Page 1: overview
total_sessions = int(daily["sessions"].sum())
total_engaged = int(daily["engaged_sessions"].sum())
long = daily.melt("date", ["sessions", "engaged_sessions"], var_name="series", value_name="value")
long["series"] = long["series"].map({"sessions": "Sessions", "engaged_sessions": "Engaged sessions"})
fig_sessions = style(px.line(long, x="date", y="value", color="series", line_dash="series",
                             color_discrete_sequence=OKABE, labels={"value": "Sessions per day", "date": ""}))
daily["rate"] = daily["engaged_sessions"] / daily["sessions"]
fig_rate = style(px.line(daily, x="date", y="rate", color_discrete_sequence=[OKABE[0]],
                         labels={"rate": "Engagement rate", "date": ""}))
fig_rate.update_yaxes(tickformat=".0%", range=[0, 1])
overview = page(
    "How many sessions did the site get, and how engaged were they?", "",
    [
        card("Headline KPIs (sample data)", kpis([
            ("Sessions", f"{total_sessions:,}"), ("Engaged sessions", f"{total_engaged:,}"),
            ("Engagement rate", f"{total_engaged / total_sessions:.1%}"),
        ])),
        card("Sessions and engaged sessions per day (sample data)", figure_html(
            fig_sessions, "Line chart of daily sessions and engaged sessions, November 2020 to January 2021.")),
        card("Engagement rate per day (sample data)", figure_html(
            fig_rate, "Line chart of daily engagement rate, engaged sessions divided by sessions.")),
    ],
    "<em>Sessions</em>: distinct user_pseudo_id + ga_session_id. <em>Engaged sessions</em>: 10 or more seconds of "
    "engagement, a purchase, or 2 or more page views (GA4 rule, rebuilt from events). <em>Engagement rate</em>: "
    "engaged sessions divided by sessions.",
    "Sample data from a different organisation's ecommerce site; patterns do not describe CMRD users. The engaged "
    "rule is rebuilt from events and not compared with GA4's own flag. Obfuscation and nulls may affect counts.",
)

# Page 2: audience
users = daily.assign(month=daily["date"].dt.to_period("M").dt.to_timestamp()).groupby("month", as_index=False)[
    ["new_users", "returning_users"]].sum().melt("month", var_name="type", value_name="n")
users["type"] = users["type"].map({"new_users": "New users", "returning_users": "Returning users"})
audience = page(
    "Who visited: new or returning users, which channels and devices?", "",
    [
        card("New and returning users, share of daily active users by month (sample data)", figure_html(
            share_fig(users, "type", "n"), "Stacked bar chart by month of new and returning users, percentages labelled.")),
        card("Channel mix, share of sessions by month (sample data)", figure_html(
            share_fig(channel, "channel", "sessions"), "Stacked bar chart by month of the share of sessions by channel.")),
        card("Device split, share of sessions by month (sample data)", figure_html(
            share_fig(device, "device_category", "sessions"), "Stacked bar chart by month of the share of sessions by device.")),
    ],
    "<em>New users</em>: users with a session numbered 1 that day. <em>Returning users</em>: active that day and not "
    "new. Both are daily distinct counts, so shares are of user-days, not distinct users. <em>Channel mix</em>: share "
    "of sessions by channel from traffic_source medium. <em>Device split</em>: share of sessions by device category.",
    "Channel is the user's first-touch traffic_source in this dataset, not the session's source; \"Other\" collects "
    "every medium not listed. Sample data from a different organisation; not CMRD users.",
)

# Page 3: funnel
ftab = funnel_window.groupby(["step_order", "step"], as_index=False)["sessions"].sum().sort_values("step_order")
ftab["drop_off"] = 1 - ftab["sessions"] / ftab["sessions"].shift()
fig_funnel = px.bar(ftab, x="sessions", y="step", orientation="h", text=ftab["sessions"].map("{:,}".format),
                    color_discrete_sequence=[OKABE[0]], labels={"sessions": "Sessions", "step": ""})
fig_funnel.update_yaxes(autorange="reversed")
fig_funnel = style(fig_funnel, 300)
tbl = pd.DataFrame({
    "Step": ftab["step"], "Sessions": ftab["sessions"].map("{:,}".format),
    "Drop-off from previous step": ftab["drop_off"].map(lambda v: "n/a" if pd.isna(v) else f"{v:.1%}"),
}).to_html(index=False, border=0)
funnel_page = page(
    "Where do sessions drop out between viewing an item and purchasing?",
    f"Funnel window: {funnel_start:%d %b %Y} to 31 Jan 2021. Earlier days are excluded because the "
    "raw sample has no or partial add_to_cart events on 1 to 24 Nov 2020.",
    [
        card("Sessions reaching each funnel step (sample data)", figure_html(
            fig_funnel, "Horizontal bar chart of sessions at view_item, add_to_cart, begin_checkout and purchase, decreasing at each step.")),
        card("Step drop-off (sample data)", tbl),
    ],
    "<em>Funnel sessions</em>: sessions with at least one event of that step; order within a session is not checked. "
    "<em>Step drop-off</em>: 1 minus (sessions at step divided by sessions at the previous step).",
    "Not a strict sequence, so drop-off is indicative. Totals cover only the funnel window. Sample data from a "
    "different organisation; not CMRD users.",
)

CSS = """
body{font-family:system-ui,Segoe UI,Arial,sans-serif;margin:0;color:#1a1a1a;background:#fff}
header{padding:16px 24px;border-bottom:1px solid #ccc} h1{margin:0;font-size:1.4rem}
.page{padding:16px 24px;border-bottom:2px solid #ddd} h2{font-size:1.2rem}
.banner{border-left:6px solid #0072B2;padding:8px 12px;background:#f2f6fa}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:16px}
.card{border:1px solid #ccc;border-radius:6px;padding:8px 12px} h3{font-size:1rem;margin:4px 0}
.kpis{display:flex;gap:16px;flex-wrap:wrap}.kpi{border:1px solid #888;border-radius:6px;padding:12px 16px}
.v{font-size:1.8rem;font-weight:700}.l{font-size:.9rem}
.note{font-size:.85rem;max-width:110ch} figure{margin:0} .sr{position:absolute;left:-9999px}
table{border-collapse:collapse} td,th{padding:4px 12px;text-align:left;border-bottom:1px solid #ddd}
"""

html = (
    '<!doctype html><html lang="en-GB"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    "<title>GA4 sample ecommerce performance dashboard (Python)</title>"
    f"<style>{CSS}</style><script>{get_plotlyjs()}</script></head><body>"
    "<header><h1>GA4 sample ecommerce performance dashboard</h1></header><main>"
    + overview + audience + funnel_page + "</main></body></html>"
)
OUT.parent.mkdir(exist_ok=True)
OUT.write_text(html, encoding="utf-8")
print(f"Wrote {OUT.relative_to(ROOT)}")
