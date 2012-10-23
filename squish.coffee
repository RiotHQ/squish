$? () ->
  return unless window?.history?.pushState
  pages = "{{SQUISH}}"
  window.pages = pages
  body = $('body')
  
  showPage = (page) ->
    window._gaq?.push(['_trackPageView'])
    $('body').html page.body
  
  window.onpopstate = (event) =>
    if !event.state
      url = document.location.pathname
      url = url.substring(1) if url[0] == "/"
      if page = pages[url]
        showPage(page)

  $("a[href*='.html']").live 'click', (e) ->
    unless $(this).attr('data-no-squish')
      url = $(this)[0].href
      url = url.replace(document.location.origin+'/', '')
      if page = pages[url]
        e.preventDefault()
        window.history.pushState '', page.title, document.location.origin+"/"+url
        showPage(page)