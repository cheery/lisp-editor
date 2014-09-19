class List
    constructor: (@list, @label="", @uid="") ->
        @length = @list.length
        @parent = null
        reparent @list, @
    
    copy: () ->
        return new List (node.copy() for node in @list), @label, @uid

    yank: (start, stop) ->
        return new List (node.copy() for node in @list[start...stop])

    kill: (start, stop) ->
        list = @list[start...stop]
        @list[start...stop] = []
        @length = @list.length
        n.parent = null for n in list
        refresh(@)
        return new List list

    put: (index, list) ->
        return false unless isList(list)
        @list[index...index] = (n.parent = @ for node in list.list)
        @length = @list.length
        refresh(@)
        @list.list = []
        return true

    indexOf: (node) -> @list.indexOf(node)

class Text
    constructor: (@text, @label="", @uid="") ->
        @length = @text.length
        @parent = null

    copy: () ->
        return new Text @text, @label, @uid

    yank: (start, stop) ->
        return new Text @text[start...stop]

    kill: (start, stop) ->
        text = @text[start...stop]
        @text = @text[...start] + @text[stop...]
        @length = @text.length
        refresh(@)
        return new Text text

    put: (index, node, copy=true) ->
        return false unless isText(node)
        @text = @text[...index] + node.text + @text[index...]
        @length = @text.length
        refresh(@)
        return true

class Mark
    constructor: (@label="", @uid="") ->
        @parent = null

    copy: () ->
        return new Mark @label, @uid

env.List = (args...) -> new List args...
env.Text = (args...) -> new Text args...
env.Mark = (args...) -> new Mark args...

env.isList = (node, label) ->
    node instanceof List and (node.label == label or not label?)

env.isText = (node, label) ->
    node instanceof Text and (node.label == label or not label?)

env.isMark = (node, label) ->
    node instanceof Mark and (node.label == label or not label?)

env.relabel = (node, label) ->
    node.label = label
    refresh(node)

env.hierarchy = (node) ->
    a = []
    while node?
        a.push node
        node = node.parent
    return a.reverse()

reparent = (nodes, parent) ->
    for node in nodes
        throw "cannot reparent, node not detached" if node.parent?
        node.parent = parent

refresh = (node) ->
    root = node
    root = root.parent while root.parent?
    if root.document?
        root.document.refresh(node)
