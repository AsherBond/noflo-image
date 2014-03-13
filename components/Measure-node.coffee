noflo = require 'noflo'
sizeOf = require 'image-size'
urlUtil = require 'url'
needle = require 'needle'

class Measure extends noflo.AsyncComponent
  description: 'Load image from URL or path and get dimensions'
  icon: 'picture-o'
  constructor: ->
    @inPorts =
      url: new noflo.Port 'string'
    @outPorts =
      dimensions: new noflo.Port 'array'
      error: new noflo.Port 'object'
    super 'url', 'dimensions'

  doAsync: (url, callback) ->
    onLoad = (err, dimensions) =>
      if err
        onError err
        return
      @outPorts.dimensions.beginGroup url
      @outPorts.dimensions.send [dimensions.width, dimensions.height]
      @outPorts.dimensions.endGroup()
      @outPorts.dimensions.disconnect()
      callback null

    onError = (err) ->
      err.url = url
      return callback err

    urlOptions = urlUtil.parse url
    if urlOptions.protocol
      # Remote image
      # TODO replace this with custom http/s calls that only get first few k
      needle.get url, (err, response) ->
        if err
          onError err
          return
        buffer = new Buffer response
        sizeOf buffer, onLoad
    else
      # Local image
      sizeOf url, onLoad

exports.getComponent = -> new Measure
