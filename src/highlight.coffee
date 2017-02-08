_ = require 'underscore-plus'
compareVersions = require('compare-versions')

escapeChar = (match) ->
  switch match
    when '&' then '&amp;'
    when '"' then '&quot;'
    when "'" then '&#39;'
    when '<' then '&lt;'
    when '>' then '&gt;'
    when ' ' then '&nbsp;'
    else match

escapeString = (string) ->
  string.replace /[&"'<>]/g, escapeChar

escapeStringNbsp = (string) ->
  string.replace /[&"'<> ]/g, escapeChar

pushScope = (scopeStack, scope, html) ->
  scopeStack.push(scope)
  html += "<span class=\"#{scope.replace(/\.+/g, ' ')}\">"

popScope = (scopeStack, html) ->
  scopeStack.pop()
  html += '</span>'

updateScopeStack = (scopeStack, desiredScopes, html) ->
  excessScopes = scopeStack.length - desiredScopes.length
  if excessScopes > 0
    html = popScope(scopeStack, html) while excessScopes--

  # pop until common prefix
  for i in [scopeStack.length..0]
    break if _.isEqual(scopeStack[0...i], desiredScopes[0...i])
    html = popScope(scopeStack, html)

  # push on top of common prefix until scopeStack is desiredScopes
  for j in [i...desiredScopes.length]
    html = pushScope(scopeStack, desiredScopes[j], html)

  html


module.exports =
highlightSync = (options = {}) ->
  registry = atom.grammars
  {fileContents, scopeName, nbsp, lineDivs, editorDiv,
    wrapCode, editorDivTag, editorDivClass, nullScope} = options
  nbsp ?= true
  lineDivs ?= false
  editorDiv ?= false
  wrapCode ?= false
  editorDivTag ?= 'div'
  editorDivClass ?= 'editor editor-colors'
  nullScope ?= 'text.plain.null-grammar'

  grammar = registry.grammarForScopeName(scopeName) ? (registry.grammarForScopeName(nullScope) if nullScope)
  throw new Error("Grammar #{scopeName} not found, and no #{nullScope} grammar") unless grammar?

  lineTokens = grammar.tokenizeLines(fileContents)

  # Remove trailing newline
  if lineTokens.length > 0
    lastLineTokens = lineTokens[lineTokens.length - 1]

    if lastLineTokens.length is 1 and lastLineTokens[0].value is ''
      lineTokens.pop()

  escape = if nbsp then escapeStringNbsp else escapeString

  html = ''
  html = "<#{editorDivTag} class=\"#{editorDivClass}\">" if editorDiv
  html += "<code>" if wrapCode
  for tokens in lineTokens
    scopeStack = []
    html += '<div class="line">' if lineDivs
    for {value, scopes} in tokens
      value = ' ' unless value
      if compareVersions(atom.getVersion(), '1.13.0') >= 0
        scopes = scopes.map (s) -> "syntax--#{s.replace(/\./g, '.syntax--')}"
      html = updateScopeStack(scopeStack, scopes, html)
      html += "<span>#{escape(value)}</span>"
    html = popScope(scopeStack, html) while scopeStack.length > 0
    html += '\n'
    html += '</div>' if lineDivs
  html += "</code>" if wrapCode
  html += "</#{editorDivTag}>" if editorDiv
  html
