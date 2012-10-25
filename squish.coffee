showPage = (page) ->
  doc = document.implementation.createHTMLDocument ''
  doc.open 'replace'
  doc.write page.body
  doc.close
  doc

  document.documentElement.replaceChild doc.body, document.body

  window._gaq?.push(['_trackPageView'])


window.onpopstate = (event) =>
  if !event.state
    url = document.location.pathname
    url = url.substring(1) if url[0] == "/"
    if page = window.pages[url]
      showPage(page)

supportsSquish = ->
  window.history and window.history.pushState and window.history.replaceState and window.history.state != undefined and document.implementation?.createHTMLDocument?

isSquishable = (el) ->
  el.nodeName == 'A' and el.href and /\.html$/.test(el.href) and not el.getAttribute('data-no-squish')

if supportsSquish
  document.addEventListener 'click', (e) ->
    el = e.target
    if isSquishable el
      url = el.href
      url = url.replace(document.location.origin+'/', '')
      if page = window.pages[url]
        e.preventDefault()
        window.history.pushState '', page.title, document.location.origin+"/"+url
        showPage(page)

  window.pages = "{{SQUISH}}"