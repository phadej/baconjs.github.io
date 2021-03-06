common = require "../bacon.js/readme/common.coffee"
marked = require "marked"
_ = require "lodash"

renderer = new marked.Renderer
renderer.code = (code, lang) ->
  '<textarea class="code">' + code + '</textarea>'

marked.setOptions
  renderer: renderer

renderToc = (elements) ->
  toc = ""
  _.each elements, (element) ->
    switch element.type
      when "subsection"
        toc += '- [' + element.name + '](#' + common.anchorName(element.name) + ')' + '\n'
      when "subsubsection"
        toc += '    - [' + element.name + '](#' + common.anchorName(element.name) + ')' + '\n'

  _.map elements, (element) ->
    switch element.type
      when "toc"
        type: "text"
        content: toc
      else
        element

renderSignature = (parsedSignature) ->
  n = if parsedSignature.n then "new " else ""
  o = parsedSignature.namespace
  m = parsedSignature.method

  name = (n + o + "." + m)

  params = parsedSignature.params?.filter (p) ->
    p.name != "@"
  params = params?.map (p, i) ->
    r = p.name
    if i != 0
      r = ", " + r

    if p.splat
      r = r + "..."

    if p.optional
      r = "[" + r + "]"
      if i != 0
        r = " " + r

    r

  if params
    name + "(" + params.join("") + ")"
  else
    name

renderElement = (element) ->
  switch element.type
    when "text"
      marked(element.content) + "\n"
    when "section"
      '<h1>' + element.name + '</h1>\n'
    when "subsection"
      '<h2><a name="' + common.anchorName(element.name) + '"></a>' + element.name + '</h2>\n'
    when "subsubsection"
      '<h3><a name="' + common.anchorName(element.name) + '"></a>' + element.name + '</h3>\n'
    when "fn"
      anchor = '<a name="' + element.anchorName + '"></a>'
      md = anchor + "\n[`" + renderSignature(element.parsedSignature) + '`](#' + element.anchorName + ' "' +  element.signature + '") ' + element.content
      marked(md)
    when "logo"
      undefined
    when "marble"
      html = ''
      html += '<div class="bacon-marble">\n'
      element.i.forEach (i) ->
        html += '<div class="bacon-input" x-bacon-input="' + i + '"></div>\n'
      html += '<div class="bacon-output" x-bacon-output="' + element.o + '"></div>\n'
      html += '</div>\n'
      html
    else
      throw new Error("Unknown token type: " + element.type)

pickSection = (sectionName, elements) ->
  include = false
  result = []
  elements.forEach (element) ->
    if element.type == "section"
      include = element.name == sectionName

    if include
      result.push element

  result

render = (doc) ->
  elements = _.cloneDeep doc.elements

  elements = pickSection "API", elements
  elements.splice 1, 0, 
    type: "toc"

  elements = common.preprocess elements

  elements = renderToc elements

  _.chain(elements)
    .map(renderElement)
    .compact()
    .join("\n\n")
    .value() + "\n"

module.exports = render
