noflo = require 'noflo'
superagent = require 'superagent'

class ToFullscale extends noflo.AsyncComponent
  constructor: ->
    @inPorts = new noflo.InPorts
      url:
        datatype: 'string'
    @outPorts = new noflo.OutPorts
      url:
        datatype: 'string'
      error:
        datatype: 'object'

    super 'url', 'url'

  doAsync: (url, callback) ->
    newUrl = url

    if url.indexOf('staticflickr.com') isnt -1
      newUrl = @convertFlickr url, callback

    if url.indexOf('wordpress.com') isnt -1
      newUrl = @convertWordpress url, callback

    if url.indexOf('wikimedia.org') isnt -1
      newUrl = @convertWikimedia url, callback

    if url.match /[-_](small|thumb)/
      return @tryFindingFullscale url, callback

    @outPorts.url.beginGroup url
    @outPorts.url.send newUrl
    @outPorts.url.endGroup()
    callback null

  convertFlickr: (url) ->
    # See docs in https://www.flickr.com/services/api/misc.urls.html
    format = url.match /_(.)\.(gif|png|jpg)/
    if format
      # We already have the original
      return url if format[1] is 'o'

      # Another format, return large
      return url.replace(/_(.)\.(gif|png|jpg)/, '_b.$2')

    # Non-specified format, return large
    return url.replace(/\.(gif|png|jpg)/, '_b.$1')

  convertWordpress: (url) ->
    return url.replace(/\?w=[\d]+/, '')

  convertWikimedia: (url) ->
    return url unless url.match /\/commons\/thumb\//
    url.replace /\/commons\/(thumb)\/([0-9])\/([0-9][a-z])\/(.*)[\\\/][^\\\/]*/, '/commons/$2/$3/$4'

  tryFindingFullscale: (url, callback) ->
    # Convert
    newUrl = url
    fullUrl = url.replace /[-_](small|thumbnail|thumb)/, ''
    # Verify that it exists
    superagent.head fullUrl
    .end (err, res) =>
      return callback err if err
      newUrl = fullUrl if res and res.statusCode is 200
      @outPorts.url.beginGroup url
      @outPorts.url.send newUrl
      @outPorts.url.endGroup()
      callback null

exports.getComponent = -> new ToFullscale
