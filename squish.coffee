# Squish.coffee.
# Highly, highly influenced by Turbolinks.

initialized    = false
currentState   = null
referer        = document.location.href
loadedAssets   = null
pageCache      = {}
createDocument = null
requestMethod  = document.cookie.match(/request_method=(\w+)/)?[1].toUpperCase() or ''

pages = "{{SQUISH}}"

visit = (url) ->
  if browserSupportsPushState
    cacheCurrentPage()
    reflectNewUrl url
    fetchReplacement url
  else
    document.location.href = url

fetchReplacement = (url) ->

  # Remove hash from url to ensure IE 10 compatibility
  safeUrl = removeHash url
  
  if url.indexOf document.location.host
    url = url.split(document.location.host)[1]
  
  if url[0] == "/" then url = url[1..-1]

  if pages[url]
    doc = createDocument pages[url]['body']
    body = doc.body
    title = pages[url]['title']
    
    changePage pages[url]['title'], body, "runScripts"
    
    reflectRedirectedUrl(url)
    
    if document.location.hash
      document.location.href = document.location.href
    else
      resetScrollPosition()
      
    triggerEvent 'page:load'
  else
    document.location = url

fetchHistory = (state) ->
  cacheCurrentPage()

  if page = pageCache[state.position]
    changePage page.title, page.body
    recallScrollPosition page
  # else
    # Load page.
    # fetchReplacement document.location.href

cacheCurrentPage = ->
  rememberInitialPage()

  pageCache[currentState.position] =
    url:       document.location.href,
    body:      document.body,
    title:     document.title,
    positionY: window.pageYOffset,
    positionX: window.pageXOffset

  constrainPageCacheTo(10)

constrainPageCacheTo = (limit) ->
  for own key, value of pageCache
    pageCache[key] = null if key <= currentState.position - limit

changePage = (title, body, runScripts) ->
  document.title = title
  document.documentElement.replaceChild body, document.body
  removeNoscriptTags()
  executeScriptTags() if runScripts
  currentState = window.history.state
  triggerEvent 'page:change'

executeScriptTags = ->
  scripts = Array::slice.call document.body.getElementsByTagName 'script'
  for script in scripts when script.type in ['', 'text/javascript']
    copy = document.createElement 'script'
    copy.setAttribute attr.name, attr.value for attr in script.attributes
    copy.appendChild document.createTextNode script.innerHTML
    { parentNode, nextSibling } = script
    parentNode.removeChild script
    parentNode.insertBefore copy, nextSibling

removeNoscriptTags = ->
  noscriptTags = Array::slice.call document.body.getElementsByTagName 'noscript'
  noscript.parentNode.removeChild noscript for noscript in noscriptTags

reflectNewUrl = (url) ->
  if url isnt document.location.href
    referer = document.location.href
    window.history.pushState { squish: true, position: currentState.position + 1 }, '', url

reflectRedirectedUrl = (location) ->
  if location isnt document.location.pathname + document.location.search
    locationString = location.toString()
    if locationString.match(/\.html$/)
      locationString = locationString.slice(0, -5)
    if locationString == "index"
      locationString = "/"
    window.history.replaceState currentState, '', locationString + document.location.hash

rememberCurrentUrl = ->
  window.history.replaceState { squish: true, position: Date.now() }, '', document.location.href

rememberCurrentState = ->
  currentState = window.history.state

rememberInitialPage = ->
  unless initialized
    rememberCurrentUrl()
    rememberCurrentState()
    createDocument = browserCompatibleDocumentParser()
    initialized = true

recallScrollPosition = (page) ->
  window.scrollTo page.positionX, page.positionY

resetScrollPosition = ->
  window.scrollTo 0, 0

removeHash = (url) ->
  link = url
  unless url.href?
    link = document.createElement 'A'
    link.href = url
  link.href.replace link.hash, ''


triggerEvent = (name) ->
  event = document.createEvent 'Events'
  event.initEvent name, true, true
  document.dispatchEvent event

extractTrackAssets = (doc) ->
  (node.src || node.href) for node in doc.head.childNodes when node.getAttribute?('data-squish-track')?

assetsChanged = (doc) ->
  loadedAssets ||= extractTrackAssets document
  fetchedAssets  = extractTrackAssets doc
  fetchedAssets.length isnt loadedAssets.length or intersection(fetchedAssets, loadedAssets).length isnt loadedAssets.length

intersection = (a, b) ->
  [a, b] = [b, a] if a.length > b.length
  value for value in a when value in b

extractBody = (doc) ->
  [doc.body, 'runScripts']
  
extractTitleAndBody = (doc) ->
  title = doc.querySelector 'title'
  [ title?.textContent, doc.body, 'runScripts' ]

browserCompatibleDocumentParser = ->
  createDocumentUsingParser = (html) ->
    (new DOMParser).parseFromString html, 'text/html'

  createDocumentUsingDOM = (html) ->
    doc = document.implementation.createHTMLDocument ''
    doc.documentElement.innerHTML = html
    doc

  createDocumentUsingWrite = (html) ->
    doc = document.implementation.createHTMLDocument ''
    doc.open 'replace'
    doc.write html
    doc.close()
    doc

  # Use createDocumentUsingParser if DOMParser is defined and natively
  # supports 'text/html' parsing (Firefox 12+, IE 10)
  #
  # Use createDocumentUsingDOM if createDocumentUsingParser throws an exception
  # due to unsupported type 'text/html' (Firefox < 12, Opera)
  #
  # Use createDocumentUsingWrite if:
  #  - DOMParser isn't defined
  #  - createDocumentUsingParser returns null due to unsupported type 'text/html' (Chrome, Safari)
  #  - createDocumentUsingDOM doesn't create a valid HTML document (safeguarding against potential edge cases)
  try
    if window.DOMParser
      testDoc = createDocumentUsingParser '<html><body><p>test'
      createDocumentUsingParser
  catch e
    testDoc = createDocumentUsingDOM '<html><body><p>test'
    createDocumentUsingDOM
  finally
    unless testDoc?.body?.childNodes.length is 1
      return createDocumentUsingWrite


installClickHandlerLast = (event) ->
  unless event.defaultPrevented
    document.removeEventListener 'click', handleClick, false
    document.addEventListener 'click', handleClick, false

handleClick = (event) ->
  unless event.defaultPrevented
    link = extractLink event
    if link.nodeName is 'A' and !ignoreClick(event, link)
      visit link.href
      event.preventDefault()


extractLink = (event) ->
  link = event.target
  link = link.parentNode until !link.parentNode or link.nodeName is 'A'
  link

crossOriginLink = (link) ->
  location.protocol isnt link.protocol or location.host isnt link.host

anchoredLink = (link) ->
  ((link.hash and removeHash(link)) is removeHash(location)) or
    (link.href is location.href + '#')

nonHtmlLink = (link) ->
  url = removeHash link
  url.match(/\.[a-z]+(\?.*)?$/g) and not url.match(/\.html?(\?.*)?$/g)

noTurbolink = (link) ->
  until ignore or link is document
    ignore = link.getAttribute('data-no-squish')?
    link = link.parentNode
  ignore

targetLink = (link) ->
  link.target.length isnt 0

nonStandardClick = (event) ->
  event.which > 1 or event.metaKey or event.ctrlKey or event.shiftKey or event.altKey

ignoreClick = (event, link) ->
  crossOriginLink(link) or anchoredLink(link) or nonHtmlLink(link) or noTurbolink(link) or targetLink(link) or nonStandardClick(event)


initializeSquish = ->
  document.addEventListener 'click', installClickHandlerLast, true
  window.addEventListener 'popstate', (event) ->
    fetchHistory event.state if event.state?.squish
  , false

browserSupportsPushState =
  window.history and window.history.pushState and window.history.replaceState and window.history.state != undefined

browserIsntBuggy =
  !navigator.userAgent.match /CriOS\//

requestMethodIsSafe =
  requestMethod in ['GET','']

initializeSquish() if browserSupportsPushState and browserIsntBuggy and requestMethodIsSafe

# Call Squish.visit(url) from client code
@Squish = { visit }
