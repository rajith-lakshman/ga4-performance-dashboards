# How CMRD pages describe themselves to GA4

Every page on the CMRD website (www.cmrd.lk) includes a small header snippet. It pushes three page-level values into the Google Tag Manager (GTM) data layer: `language`, `section` and `content_type`. GTM can then pass them to GA4, so reports can be split by language, section and content type. The CMRD page inventory in this repo (`data/cmrd/page-inventory.csv`) uses the same three columns and values.

This is the same snippet, shared so reviewers can see how the values are produced. The GTM container ID is replaced with a placeholder.

## What it does

1. **Language** comes from the page's own language setting (`$lang`: 3, 4 or 5 maps to `en`, `si` or `ta`). Anything else is left out.
2. **Section** is the first folder in the page's file path under the language folder (`about`, `projects`, `publications`, `team`, `contact`, `links`). An `index` page at the top level is `home`. Anything else is `other`.
3. **Content type** is mapped from the section (for example `projects` becomes `project`). Pages in `publications` are classified by file name: `blog20...` is `blog`, `videos` is `video`, a name containing `comic` is `comic`, and everything else is `listing`.
4. The values are written to `window.dataLayer` as JSON, then the GTM script loads.

## Privacy by design

- **Allowlists only.** Each value is chosen from a fixed list in the code. Nothing is copied from `$_GET`, `$_SERVER['REQUEST_URI']` or any other request data, so a visitor cannot inject text into the data layer, and query strings, search terms or form input never reach it.
- **No personal data.** The three values describe the page, not the visitor. The snippet sets no user ID and reads no cookie, name, email or IP address.
- **Safe output.** `json_encode` runs with the `JSON_HEX_*` flags, so the output cannot break out of the script tag.
- **The server path never leaves the server.** `$mypath` is used to work out the section and type, but only the resulting labels are sent.

GA4 itself assigns each browser a pseudonymous ID (`user_pseudo_id`). That is outside this snippet, and this repo never contains it: only aggregated counts are stored in `data/GA4-demo/`, and those come from the Google sample dataset, not from CMRD.

## The snippet

`$lang` and `$mypath` are set by each page before this code runs.

```php
<?php
// Values come only from this allowlist, keyed on the server-side file path
// ($mypath, set by the page), never from $_GET, $_SERVER['REQUEST_URI'] or other request data.
$dl_languages = [3 => 'en', 4 => 'si', 5 => 'ta'];
$dl_sections  = ['about', 'projects', 'publications', 'team', 'contact', 'links'];
$dl_language  = $dl_languages[$lang] ?? null;
$dl_rel   = preg_replace('#^.*/(en|si|ta)/#', '', str_replace('\\', '/', $mypath));
$dl_parts = explode('/', $dl_rel);
$dl_base  = preg_replace('/-test$/', '', basename($dl_rel, '.php'));
$dl_first = $dl_parts[0];
if (count($dl_parts) === 1 && $dl_base === 'index') {
    $dl_section = 'home';
} elseif (in_array($dl_first, $dl_sections, true)) {
    $dl_section = $dl_first;
} else {
    $dl_section = 'other';
}
$dl_types = [
    'home' => 'home', 'about' => 'about', 'team' => 'team',
    'contact' => 'contact', 'links' => 'links', 'projects' => 'project',
];
if ($dl_section === 'publications') {
    if (strpos($dl_base, 'blog20') === 0)         { $dl_type = 'blog'; }
    elseif ($dl_base === 'videos')                { $dl_type = 'video'; }
    elseif (stripos($dl_base, 'comic') !== false) { $dl_type = 'comic'; }
    else                                          { $dl_type = 'listing'; }
} else {
    $dl_type = $dl_types[$dl_section] ?? 'other';
}
$dl_data = ['section' => $dl_section, 'content_type' => $dl_type];
if ($dl_language !== null) { $dl_data['language'] = $dl_language; }
?>
<script>
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push(<?php echo json_encode($dl_data, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>);
</script>
<script async src="https://www.googletagmanager.com/gtm.js?id=GTM-XXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
</script>
```

## Example output

A page at `en/projects/example.php` pushes `{"section":"projects","content_type":"project","language":"en"}`.

## From the data layer to the inventory

The inventory is a table of pages with the same three columns. Every `language`, `section` and `content_type` value in `data/cmrd/page-inventory.csv` is one this snippet can produce. The snippet only sets values on live pages; it does not write the CSV.

## Not in the snippet

- The GTM container configuration (data layer variables, the GA4 tag and any custom dimensions in GA4) is not part of this repo. The snippet only sets the values.
- The `gtag('js', ...)` lines define a helper but contain no GA4 measurement ID or `config` call.
