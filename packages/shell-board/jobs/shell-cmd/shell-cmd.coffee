### jshint node:true ###

childProcess = require 'child_process'
_ = require 'lodash'
xtermColors = require 'xterm-colors'

convertAnsi = (src, bright = 0) ->
  escape = src
  escape = escape.replace(/^\033\[/, '').replace(/m$/, '')
  escape = escape.replace /38;5;([\d]+)/, (match, colorStr) ->
    color = parseInt colorStr, 10
    'fg##' + xtermColors[color]
  escape = escape.replace /38;2;([\d]+);([\d]+);([\d]+)/, (match, r, g, b) ->
    'fg#rgb(' + r + ', ' + g + ', ' + b + ')'
  escape = escape.replace /48;5;([\d]+)/, (match, colorStr) ->
    color = parseInt colorStr, 10
    'bg##' + xtermColors[color]
  escape = escape.replace /48;2;([\d]+);([\d]+);([\d]+)/, (match, r, g, b) ->
    'bg#rgb(' + r + ', ' + g + ', ' + b + ')'
  escapes = escape.split ';'
  result = _.merge.apply _, _.compact _.map escapes, (colorStr) ->
    color = parseInt colorStr, 10
    if color is 1
      bright = 8
      {}
    else if color >= 30 and color < 38
      xtermColor = xtermColors[color - 30 + bright]
      {fg: '#' + xtermColor, fgColor: color}
    else if color >= 90 and color < 98
      xtermColor = xtermColors[color - 90 + 8]
      {fg: '#' + xtermColor, fgColor: color}
    else if /^fg#/.test colorStr
      xtermColor = colorStr.replace(/^fg#/, '')
      {fg: xtermColor, fgColor: colorStr}
    else if color >= 40 and color < 48
      xtermColor = xtermColors[color - 40]
      {bg: '#' + xtermColor, bgColor: color}
    else if color >= 100 and color < 108
      xtermColor = xtermColors[color - 100 + 8]
      {bg: '#' + xtermColor, bgColor: color}
    else if /^bg#/.test colorStr
      xtermColor = colorStr.replace(/^bg#/, '')
      {bg: xtermColor, bgColor: colorStr}
    else
      {}
  result.bright = bright
  result.src = src
  result

convertAnsiText = (text) ->
  countSpans = 0
  bright = 0
  text = text.replace /\033\(B\033\[m|\033\[[^m]+m/g, (escape) ->
    if /^\033\(B\033\[m$/.test escape
      escape = new Array(countSpans + 1).join('</span>') + "<span data-ansi-src=\"#{escape}\"></span>"
      countSpans = 0
      bright = 0
      return escape
    escape = convertAnsi escape, bright
    bright = escape.bright or 0
    style = ''
    if escape.fg?
      style += "color: #{escape.fg};"
    if escape.bg?
      style += "background-color: #{escape.bg};"
    if style.length
      countSpans += 1
      "<span style=\"#{style}\" data-ansi-src=\"#{escape.src}\" data-ansi-fg=\"#{escape.fgColor}\" data-ansi-bg=\"#{escape.bgColor}\">"
    else
      ""
  text + new Array(countSpans + 1).join '</span>'

convertLinks = (text) ->
  text = text.replace /https?:\/\/[^\s<]+/g, (link) ->
    # linkName = link.replace /.*\/([^\/]+)$/, '$1'
    "<a href=\"#{link}\" target=\"_blank\">#{link}</a>"

module.exports = (cb) ->
  return cb()  unless _.keys @config?.cmd
  options = {
    cwd: __dirname
  }
  options = _.merge options, @config?.options or {}
  options.env = _.merge {}, process.env, options.env
  if options.env?['PATH']
    options.env['PATH'] += ":#{process.env['PATH']}"
  if _.isArray @config.cmd
    @config.cmd = @config.cmd.join ' '
  childProcess.exec @config.cmd, options, (code, stdout, stderr) ->
    cb null, {
      code
      stdout
      stderr
      htmlStdout: convertLinks convertAnsiText stdout
      htmlStderr: convertLinks convertAnsiText stderr
    }
