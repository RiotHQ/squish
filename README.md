## Squish 
Squish is a way of writing fast, static HTML sites.

Instead of re-requesting every time you want another page from the site, Squish takes all your pages and caches them in Javascript on whatever page you're on.

## Full credit to:
Turbolinks. https://github.com/rails/turbolinks/ This library is like Turbolinks, but instead of requesting each page, the pages are loaded in-line.

## Limitations
• Because pushState doesn't work under file:/// URLs, neither does Squish. You may want to use http://anvilformac.com/ ;)

## USAGE

```
$ ruby squish.rb assets/javascripts
```

```html
<script type="text/javascript" src="squish.js"></script>
```