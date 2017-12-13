hl = require('../lib/highlight')
fs = require('fs')

fixture = (name) ->
  fs.readFileSync("#{__dirname}/fixtures/#{name}", encoding: 'utf8')

saveFixture = (name, data) ->
  fs.writeFileSync("#{__dirname}/fixtures/#{name}", data, encoding: 'utf8')

describe "atom-highlight", ->
  describe "js highlights", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')

    it "highlights stuff", ->
      expect(hl(scopeName: 'source.js', fileContents: fixture('code.js'))).toEqual(fixture('expect.html'))

    it "highlights stuff with options", ->
      expect(hl(
        scopeName: 'source.js'
        editorDiv: true
        wrapCode: true
        lineDivs: true
        fileContents: fixture('code.js')
      )).toEqual(fixture('expect-opts.html'))

  it "respects editorDiv option", ->
    div = document.createElement('div')
    div.innerHTML = hl(editorDiv: true, editorDivClass: 'editor-class', editorDivTag: 'editor-tag', fileContents: '')
    expect(div.firstChild.className).toEqual('editor-class')
    expect(div.firstChild.tagName.toLowerCase()).toEqual('editor-tag')

  it "respects wrapCode option", ->
    div = document.createElement('div')
    div.innerHTML = hl(wrapCode: true, fileContents: '')
    expect(div.firstChild.tagName.toLowerCase()).toEqual('code')

  it "respects lineDivs option", ->
    expect(hl(lineDivs: true, fileContents: "some\nlines")).toEqual('''
      <div class="line"><span class="syntax--text syntax--plain syntax--null-grammar"><span>some</span></span></div>
      <div class="line"><span class="syntax--text syntax--plain syntax--null-grammar"><span>lines</span></span></div>

      ''')
