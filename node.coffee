class ListNode
    constructor: (@list, @label) ->
        @parent = null
        @length = @list.length
        node.parent = @ for node in @list

    getRoot: () -> if @parent? @parent.getRoot() else @
    
    copy: () ->
        return newList (node.copy() for node in @list), @label

    yank: (start, stop) ->
        return newList (node.copy() for node in @list[start...stop])

    kill: (start, stop) ->
        list = @list[start...stop]
        @list[start...stop] = []
        @length = @list.length
        node.parent = null for node in list
        @changed()
        return newList (list)

    put: (index, list, copy=true) ->
        return false unless isList(list)
        list = (node.copy() for node in list) if copy
        node.parent = @ for node in list
        @list[index...index] = list
        @length = @list.length
        @changed()
        return true

    indexOf: (node) -> @list.indexOf node
    slice: (args...) -> @list.slice args...

    relabel: (@label) ->
        @changed()

    changed: () ->
        document = @getRoot().document
        document.wasChanged(@) if document?

    find: (node) ->

class TextNode
    constructor: (@text, @label) ->
        @parent = null
        @length = @text.length

    getRoot: () -> if @parent? @parent.getRoot() else @
    
    copy: () ->
        return newText @text, @label

    yank: (start, stop) ->
        return newText @text[start...stop]

    kill: (start, stop) ->
        text = @text[start...stop]
        @text = @text[...start] + @text[stop...]
        @length = @text.length
        @changed()
        return newText text

    put: (index, list, copy=true) ->
        return false unless isText(list)
        @text = @text[...index] + buff.text + @text[index...]
        @length = @text.length
        @changed()
        return true

    slice: (args...) -> @list.slice args...

    relabel: (@label) ->
        @changed()

    changed: () ->
        document = @getRoot().document
        document.wasChanged(@) if document?

class MarkNode
    constructor: (@label) ->
        @parent = null

    copy: () ->
        return newMark @label

    relabel: (@label) ->
        @changed()

    changed: () ->
        document = @getRoot().document
        document.wasChanged(@) if document?

window.newList = (list, label=null) -> new ListNode(list, label)
window.newText = (text, label=null) -> new TextNode(text, label)
window.newMark = (label=null) -> new MarkNode(label)
window.isList = (node, label) -> node instanceof ListNode and isLabelled node, label
window.isText = (node, label) -> node instanceof TextNode and isLabelled node, label
window.isMark = (node, label) -> node instanceof MarkNode and isLabelled node, label
window.isLabelled = (node, label) -> if label? then node.label == label else true
