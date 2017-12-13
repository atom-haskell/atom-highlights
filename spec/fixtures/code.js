const lineTokens = grammar.tokenizeLines(o.fileContents);
if (lineTokens.length > 0) {
    const lastLineTokens = lineTokens[lineTokens.length - 1];
    if (lastLineTokens.length === 1 && lastLineTokens[0].value === '') {
        lineTokens.pop();
    }
}
const escape = o.nbsp ? escapeStringNbsp : escapeString;
const html = [];
if (o.editorDiv)
    html.push(`<${o.editorDivTag} class="${o.editorDivClass}">`);
if (o.wrapCode)
    html.push('<code>');
