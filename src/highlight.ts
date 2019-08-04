import _ = require('underscore')
import compareVersions = require('compare-versions')
import {} from 'atom'

function escapeChar(match: string): string {
  switch (match) {
    case '&': return '&amp;'
    case '"': return '&quot;'
    case "'": return '&#39;'
    case '<': return '&lt;'
    case '>': return '&gt;'
    case ' ': return '&nbsp;'
    default: return match
  }
}

function escapeString(inp: string): string {
  return inp.replace(/[&"'<>]/g, escapeChar)
}

function escapeStringNbsp(inp: string): string {
  return inp.replace(/[&"'<> ]/g, escapeChar)
}

function pushScope(scopeStack: string[], scope: string, html: string[]): void {
  scopeStack.push(scope)
  html.push(`<span class="${scope.replace(/\.+/g, ' ')}">`)
}

function popScope(scopeStack: string[], html: string[]): void {
  scopeStack.pop()
  html.push('</span>')
}

function updateScopeStack(scopeStack: string[], desiredScopes: string[], html: string[]): void {
  let excessScopes = scopeStack.length - desiredScopes.length
  if (excessScopes > 0) {
    while (excessScopes--) {
      popScope(scopeStack, html)
    }
  }

  // pop until common prefix
  let lasti = 0
  for (let i = scopeStack.length; i >= 0; --i) {
    if (_.isEqual(scopeStack.slice(0, i), desiredScopes.slice(0, i))) {
      lasti = i
      break
    }
    popScope(scopeStack, html)
  }
  // push on top of common prefix until scopeStack is desiredScopes
  for (let j = lasti; j < desiredScopes.length; ++j) {
    pushScope(scopeStack, desiredScopes[j], html)
  }
}

const defaultOptions = {
  nbsp: true,
  lineDivs: false,
  editorDiv: false,
  wrapCode: false,
  editorDivTag: 'div',
  editorDivClass: 'editor editor-colors',
  nullScope: 'text.plain.null-grammar',
}

export = function highlightSync(
  options: {
    fileContents: string
    scopeName: string
  } & Partial<{
    nbsp: boolean
    lineDivs: boolean
    editorDiv: boolean
    wrapCode: boolean
    editorDivTag: string
    editorDivClass: string
    nullScope: string
  }>,
): string {
  const registry = atom.grammars.textmateRegistry || atom.grammars
  const o = {...defaultOptions, ...options}

  const grammar = registry.grammarForScopeName(o.scopeName) || (o.nullScope ? registry.grammarForScopeName(o.nullScope) : undefined)
  if (grammar === undefined) {
    throw new Error(`Grammar ${o.scopeName} not found, and no ${o.nullScope} grammar`)
  }

  const lineTokens = grammar.tokenizeLines(o.fileContents)

  // Remove trailing newline
  if (lineTokens.length > 0) {
    const lastLineTokens = lineTokens[lineTokens.length - 1]

    if (lastLineTokens.length === 1 && lastLineTokens[0].value === '') {
      lineTokens.pop()
    }
  }

  const escape = o.nbsp ? escapeStringNbsp : escapeString

  const html: string[] = []
  if (o.editorDiv) html.push(`<${o.editorDivTag} class="${o.editorDivClass}">`)
  if (o.wrapCode) html.push('<code>')
  for (const tokens of lineTokens) {
    const scopeStack: string[] = []
    if (o.lineDivs) html.push('<div class="line">')
    for (const {value, scopes} of tokens) {
      let newScopes = scopes
      if (compareVersions(atom.getVersion(), '1.13.0') >= 0) {
        newScopes = scopes.map((s: string) => `syntax--${s.replace(/\./g, '.syntax--')}`)
      }
      updateScopeStack(scopeStack, newScopes, html)
      html.push(`<span>${escape(value)}</span>`)
    }
    while (scopeStack.length > 0) {
      popScope(scopeStack, html)
    }
    if (o.lineDivs) html.push('</div>')
    html.push('\n')
  }
  if (o.wrapCode) html.push('</code>')
  if (o.editorDiv) html.push(`</${o.editorDivTag}>`)
  return html.join('')
}
