window.hoverColor = "#222"
window.selectColor = "#888"
window.selectCompositeOp = "darker"
window.padding = 8

class ListNode
    constructor: (@list) ->
        @type = 'list'
        @parent = null
        @length = @list.length
        @hover = false
        for item in @list
            item.parent = @
        #@selection = {left: 0, right: padding, row: 0}

    copy: () ->
        list = []
        for item in @list
            list.push item.copy()
        return new ListNode(list)

    yank: (start, stop) ->
        return new ListBuffer(@list[start...stop], @)

    kill: (start, stop) ->
        list = @list[start...stop]
        @list[start...stop] = []
        @length = @list.length
        return new ListBuffer(list, null)

    put: (index, buff) ->
        throw "buffer conflict" if buff.type != "listbuffer"
        if buff.link?
            @list[index...index] = buff.list.copy()
        else
            @list[index...index] = buff.list
        @length = @list.length

    mousemotion: (x, y) ->
        x -= @x
        y -= @y
        childhover = false
        for item in @list
            childhover = childhover or item.mousemotion(x, y)
        @hover = (0 <= x < @width) and (0 <= y < @height) and not childhover
        return childhover or @hover

    layout: (bc) ->
        @x = 0
        @y = 0
        @width  = 0
        @height = 0
        @rows = []

        @rows.push row = {
            offset: padding
            offsets: [padding]
            frames:  []
            height: 16
        }
        offset = padding
        for item in @list
            item.layout(bc)
            if item.type == 'cr'
                @rows.push row = {
                    offset: row.offset + row.height + padding
                    offsets: [padding]
                    frames: []
                    height: 16
                }
                @width  = Math.max(offset, @width)
                @height = Math.max(row.offset + row.height + 2*padding, @height)
                offset = padding
            else
                item.x = offset
                item.y = row.offset
                offset += padding + item.width
                row.offsets.push offset
                row.frames.push item
                row.height = Math.max(row.height, item.height)
        @width  = Math.max(offset, @width)
        @height = Math.max(row.offset + row.height + padding, @height)

        for row in @rows
            for item in row.frames
                item.y += row.height / 2 - item.height / 2

        @width  += padding if @rows.length > 1
        @height += padding if @rows.length > 1

    draw: (bc) ->
        bc.fillStyle = "white"
        bc.strokeStyle = "black"
        bc.strokeStyle = hoverColor if @hover
        bc.fillRect   @x, @y, @width, @height
        bc.strokeRect @x, @y, @width, @height
        bc.save()
        bc.translate(@x, @y)
        for item in @list
            item.draw(bc)
        if @selection
            row = @rows[@selection.row]
            bc.fillStyle = selectColor
            bc.globalCompositeOperation = selectCompositeOp

            bc.fillRect(@selection.left, row.offset, @selection.right - @selection.left, row.height)
            bc.globalCompositeOperation = "source-over"
        bc.restore()

class TextNode
    constructor: (@text) ->
        @type = 'text'
        @parent = null
        @hover = false
        @length = @text.length
        #@selection = {left: -1, right: 1}

    copy: () ->
        return new TextNode(@text)

    yank: (start, stop) ->
        return new TextBuffer(@text[start...stop], @)

    kill: (start, stop) ->
        text = @text[start...stop]
        @text[start...stop] = []
        @length = @text.length
        return new TextBuffer(text, null)

    put: (index, buff) ->
        throw "buffer conflict" if buff.type != "textbuffer"
        @text = @text[...index] + buff.text + @text[index...]
        @length = @text.length

    layout: (bc) ->
        bc.font = "16px sans-serif"
        @x = 0
        @y = 0
        @width  = bc.measureText(@text).width
        @height = 16

    mousemotion: (x, y) ->
        @hover = (@x <= x < @x+@width) and (@y <= y < @y+@height)

    draw: (bc) ->
        bc.font = "16px sans-serif"
        bc.fillStyle = "black"
        bc.fillStyle = hoverColor if @hover
        bc.fillText @text, @x, @y+@height/2, @width

        if @selection
            bc.fillStyle = selectColor
            bc.globalCompositeOperation = selectCompositeOp
            bc.fillRect(@x+@selection.left, @y, @selection.right - @selection.left, @height)
            bc.globalCompositeOperation = "source-over"

class Carriage
    constructor: (@list) ->
        @type = 'cr'

    mousemotion: (x, y) ->
        return false

    layout: (bc) ->
        @x = 0
        @y = 0
        @height = 0
        @width  = 0

    draw: (bc) ->

class ListBuffer
    constructor: (@list, @link) ->
        @type = "listbuffer"

class TextBuffer
    constructor: (@text, @link) ->
        @type = "textbuffer"

window.cr = () -> new Carriage()
window.text = (text) -> new TextNode(text)
window.list = (data...) -> new ListNode(data)

window.listbuffer = (list...) -> new ListBuffer(list, null)
window.textbuffer = (text) -> new TextBuffer(text, null)
