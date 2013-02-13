class Url

  @tabopen: => start(false, true)
  @openWithDefault: => @start(true, false)
  @tabopenWithDefault: => @start(true, true)
  @start: (with_default, new_tab) ->
    title = (if new_tab then 'TabOpen: ' else 'Open: ')
    content = (if with_default then location.href else '')
    Dialog.start title, content, search, new_tab


  @search: (keyword) ->
    Post action: "Tab.autoComplete", keyword: keyword, default_urls: fixUrl(keyword)


  @fixRelativePath: (url) ->
    # http://google.com
    return url if /:\/\//.test(url)

    # /admin
    return document.location.origin + url if (/^\//.test(url))

    # ../users || ./products || ../users
    url += '/' if url.match(/\/?\.\.$/) # .. -> ../

    pathname = document.location.origin + document.location.pathname.replace(/\/+/g, '/')
    for path in url.split('..')
      if path.match(/^\//)
        pathname = pathname.replace(/\/[^\/]*\/?$/, '') + path
      else if path.match(/^.\//)
        pathname = pathname.replace(/\/$/, '') + path.replace(/^.\//, '/')
    return pathname


  fixUrl = (url_str) ->
    urls = url_str.split(/, /)
    result = []

    for url in urls
      url = url.trim()
      #  /jinzhu || (.. || ./configure) && no space
      if (/^\//.test(url) || /^\.\.?\/?/.test(url)) && /^\s*\S+\s*$/.test(url)
        result.push(fixRelativePath(url))
      # Like url, for example: google.com
      else if /\./.test(url) && !/\s/.test(url)
        result.push "#{url.match("://") ? "" : "http://"}#{url}"
      # Local URL, for example: localhost:3000 || dev.local/
      else if /local(host)?($|\/|\:)/.test(url)
        result.push "#{url.match("://") ? "" : "http://"}#{url}"
      # google vrome
      else
        searchengines = Option.get('searchengines')
        name = url.replace(/^(\S+)\s.*$/, "$1"); # searchengine name: e.g: google
        keyword = encodeURIComponent url.replace(/^\S+\s+(.*)$/, "$1")

        # use the matched searchengine
        if searchengines[name]
          result.push searchengines[name].replace "{{keyword}}", keyword
          break

        url = encodeURIComponent(url)
        result.push Option.default_search_url(url)

    return result


  @parent: ->
    pathnames = location.pathname.split('/')
    hostnames = location.hostname.split('.')

    for i in [0..times()]
      if pathnames.length <= 1
        hostnames.shift() if hostnames.length > 2
      else
        pathnames.pop()

    hostname = hostnames.join('.')
    pathname = pathnames.join('/')
    port = (if location.port then (':' + location.port) else '')

    Post action: "Tab.openUrl", url: "#{location.protocol}//#{hostname}#{port}#{pathname}"

  @root: ->
    location.pathname = '/'

  @decrement: => @increment(-1)
  @increment: (dirction) ->
    count = times() * (dirction || 1)

    if document.location.href.match(/(.*?)(\d+)(\D*)$/)
      [before, number, after] = [RegExp.$1, RegExp.$2, RegExp.$3]
      newNumber = parseInt(number, 10) + count
      newNumberStr = String(newNumber > 0 ? newNumber : 0)
      # 0009<C-a> -> 0010
      if number.match(/^0/)
        while newNumberStr.length < number.length
          newNumberStr = "0" + newNumberStr

      Post action: "Tab.openUrl", url: before + newNumberStr + after


  @viewSourceNewTab: => @viewSource true
  @viewSource: (newTab) ->
    Post action: "Tab.toggleViewSource", newtab: newTab

  @shortUrl: (msg) ->
    if msg?.url
      Clipboard.copy(msg.url)
      CmdBox.set title: "[Copied] Shortened URL: #{msg.url}", timeout: 4000
    else
      CmdBox.set title: 'Shortening current URL', timeout: 4000
      Post action: "shortUrl"


  @openFromClipboardNewTab: => @openFromClipboard(true)
  @openFromClipboard: (new_tab=false) ->
    selected_value = getSelected()
    if selected_value isnt ""
      Post action: "Tab.openUrl", url: fixUrl(selected_value), newtab: new_tab
    else
      Post action: "Tab.openFromClipboard", newtab: new_tab


root = exports ? window
root.Url = Url