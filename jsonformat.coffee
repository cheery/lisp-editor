window.exportJson = (node) ->
    if isList(node)
        return {
            type: 'list'
            label: node.label
            list:(exportJson a for a in node.list)
        }
    if isText(node)
        return {
            type: 'text'
            text: node.text
            label: node.label
        }
    if isMark(node)
        return {
            type: 'mark'
            label: node.label
        }
    throw "unimplemented node at json export"

window.importJson = (json) ->
    switch json.type
        when 'list'
            list = (importJson a for a in json.list)
            node = newList(list, json.label)
            return node
        when 'text'
            node = newText(json.text, json.label)
            return node
        when 'mark'
            node = newMark(json.label)
            return node
        else
            throw "unimplemented node at json import"
