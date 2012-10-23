## Squish 

Squish is a way of writing fast, static HTML sites.

Instead of re-requesting every time you want another page from the site, Squish takes all your pages and caches them in Javascript on whatever page you're on.

The limitation:
• Squish can't replace <body> tags. That means if you're putting classes on your <body> tag, you're outta luck. Put a <div> around your content with your classes and you're golden.
• Because pushState doesn't work under file:/// URLs, neither does Squish. You may want to use http://anvilformac.com/ ;)

## USAGE

```
$ ruby squish.rb assets/javascripts
```

```html
<script type="text/javascript" src="squish.js"><script/>
```