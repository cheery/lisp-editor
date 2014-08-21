window.exportJson = (node) ->
    switch node.type
        when 'list'
            return {
                type: 'list'
                label: node.label
                list:(exportJson a for a in node.list)
            }
        when 'text'
            return {
                type: 'text'
                text: node.text
            }
        when 'cr'
            return {
                type: 'cr'
            }
        else
            throw "unimplemented node at json export"

window.importJson = (json) ->
    switch json.type
        when 'list'
            list = (importJson a for a in json.list)
            node = new ListNode(list)
            node.label = json.label
            return node
        when 'text'
            return text(json.text)
        when 'cr'
            return cr()
        else
            throw "unimplemented node at json import"
