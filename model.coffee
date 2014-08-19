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
        @hoverIndex = 0
        for item in @list
            item.parent = @

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
        for item in list
            item.parent = null
        return new ListBuffer(list, null)

    put: (index, buff) ->
        throw "buffer conflict" if buff.type != "listbuffer"
        if buff.link?
            list = (item.copy() for item in buff.list)
        else
            list = buff.list
            buff.link = @
        for item in list
            item.parent = @
        @list[index...index] = list
        @length = @list.length

    get: (index) ->
        return null unless 0 <= index < @length
        return @list[index]

    getRange: () ->
        return null unless @parent?
        start = @parent.list.indexOf(@)
        stop  = start + 1
        return {target:@parent, start, stop}

    mousemotion: (x, y) ->
        x -= @x
        y -= @y
        childhover = null
        for item in @list
            over = item.mousemotion(x, y)
            childhover = childhover or over
        @hover = (0 <= x < @width) and (0 <= y < @height) and not childhover

        for row in @rows
            if row.offset <= y < row.offset + row.height + padding
                @hoverIndex = row.start
                for o in row.offsets
                    break if x < o
                    @hoverIndex += 1
                @hoverIndex = Math.max(@hoverIndex-1, row.start)
        @hoverIndex = 0       if y < padding
        @hoverIndex = @length if y > @height
        if childhover?
            return childhover
        if @hover
            return @
        else
            return null

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
            start: 0
            stop:  0
        }
        offset = padding
        for item in @list
            item.layout(bc)
            if item.type == 'cr'
                row.stop = row.start + row.frames.length
                @rows.push row = {
                    offset: row.offset + row.height + padding
                    offsets: [padding]
                    frames: []
                    height: 16
                    start: row.stop + 1
                    stop: row.stop + 1
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
        row.stop = row.start + row.frames.length
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
        bc.strokeRect @x, @y, @width, @height if @parent?
        bc.save()
        bc.translate(@x, @y)
        for item in @list
            item.draw(bc)
        bc.restore()

    getPosition: () ->
        x = y = 0
        {x, y} = @parent.getPosition() if @parent
        return {x:x+@x, y:y+@y}

    drawSelection: (bc, start, stop) ->
        {x, y} = @getPosition()
        bc.fillStyle = selectColor
        bc.globalCompositeOperation = selectCompositeOp
        for row in @rows
            if stop < row.start
                continue
            if row.stop < start
                continue
            if row.start <= start
                left = row.offsets[start - row.start] - 1
            else
                left = 0
            if stop == start
                right = left - 2
                left -= padding - 4
            else if stop == row.start
                right = row.offsets[0]
            else if stop <= row.stop
                right = row.offsets[stop - row.start] - padding + 1
            else
                right = @width
            if right < left
                [left, right] = [right, left]
            bc.fillRect(x+left, y+row.offset - 1, right - left, row.height + padding)
        bc.globalCompositeOperation = "source-over"

class TextNode
    constructor: (@text) ->
        @type = 'text'
        @parent = null
        @hover = false
        @length = @text.length
        @offsets = []
        @hoverIndex = 0

    copy: () ->
        return new TextNode(@text)

    yank: (start, stop) ->
        return new TextBuffer(@text[start...stop], @)

    kill: (start, stop) ->
        text = @text[start...stop]
        @text = @text[...start] + @text[stop...]
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
        @offsets = [0]
        for i in [1..@length]
            @offsets.push bc.measureText(@text[0...i]).width

    getRange: () ->
        return null unless @parent?
        start = @parent.list.indexOf(@)
        stop  = start + 1
        return {target:@parent, start, stop}

    mousemotion: (x, y) ->
        @hover = (@x <= x < @x+@width) and (@y <= y < @y+@height)
        @hoverIndex = 0
        for o in @offsets
            break if x < o + @x
            @hoverIndex += 1
        @hoverIndex = Math.max(@hoverIndex - 1, 0)
        if @hover
            return @
        return null

    draw: (bc) ->
        bc.font = "16px sans-serif"
        bc.fillStyle = "black"
        bc.fillStyle = hoverColor if @hover
        bc.fillText @text, @x, @y+@height/2, @width

    getPosition: () ->
        x = y = 0
        {x, y} = @parent.getPosition() if @parent
        return {x:x+@x, y:y+@y}

    drawSelection: (bc, start, stop) ->
        {x, y} = @getPosition()
        left  = @offsets[start] - 1
        right = @offsets[stop] + 1
        bc.fillStyle = selectColor
        bc.globalCompositeOperation = selectCompositeOp
        bc.fillRect(x+left, y, right - left, @height)
        bc.globalCompositeOperation = "source-over"

class Carriage
    constructor: (@list) ->
        @type = 'cr'

    copy: () ->
        return new Carriage()

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

window.isText = (node) -> node? and node.type == 'text'
window.isList = (node) -> node? and node.type == 'list'
window.isCr   = (node) -> node? and node.type == 'cr'

window.nodeType = (node) ->
    return null unless node? and node.type?
    return node.type
