### jshint node:true ###

childProcess = require 'child_process'
_ = require 'lodash'
xtermColors = require 'xterm-colors'

convertAnsi = (escape) ->
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
  escape = escape.split ';'
  bright = 0
  escape = _.merge.apply _, _.compact _.map escape, (colorStr) ->
    color = parseInt colorStr, 10
    if color is 1
      bright = 8
      {}
    else if color >= 30 and color < 38
      {fg: '#' + xtermColors[color - 30 + bright]}
    else if color >= 90 and color < 98
      {fg: '#' + xtermColors[color - 90 + 8]}
    else if /^fg#/.test colorStr
      {fg: colorStr.replace(/^fg#/, '')}
    else if color >= 40 and color < 48
      {bg: '#' + xtermColors[color - 40]}
    else if color >= 100 and color < 108
      {bg: '#' + xtermColors[color - 100 + 8]}
    else if /^bg#/.test colorStr
      {bg: colorStr.replace(/^bg#/, '')}
    else
      {}
  escape

convertAnsiText = (text) ->
  text = text.replace /\033\[[^m]+m/g, (escape) ->
    escape = convertAnsi escape
    style = ''
    if escape.fg?
      style += "color: #{escape.fg};"
    if escape.bg?
      style += "background-color: #{escape.bg};"
    if style.length
      "</span><span style=\"#{style}\">"
    else
      "</span><span>"

convertLinks = (text) ->
  text = text.replace /https?:\/\/[^\s]+/g, (link) ->
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
