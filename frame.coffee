class ListFrame
    constructor: (@node, @style) ->
        @frames = []
        @rows = [{frames:[]}]
        @parent = null

    clean: () ->
        @frames = []
        @rows = [{frames:[]}]

    push: (frame) ->
        @frames.push frame
        @rows[@rows.length-1].frames.push frame
        frame.parent = @

    newline: (breaker) ->
        @rows[@rows.length-1].rbreaker = breaker
        @rows.push {frames:[], breaker}

    layout: (bc) ->
        @x = 0
        @y = 0
        @width  = 5
        @height = 5

        caretIndex = 0
        yoffset = @style.topPadding
        verticalSpacing = 0
        indent = 0
        for row in @rows
            yoffset += verticalSpacing
            xoffset = @style.leftPadding + indent
            if (i = @node.indexOf(row.breaker)) >= 0
                caretIndex = i+1
            row.carets = []
            row.offset = yoffset
            row.height = @style.fontSize

            caretPush row, caretIndex, @style.leftPadding

            spacing = 0
            for frame in row.frames
                xoffset += spacing
                frame.layout(bc)
                if (i = @node.indexOf(frame.node)) >= 0
                    caretIndex = i + 1
                    if caretIndex >= 0
                        caretPush row, caretIndex-1, xoffset
                        caretPush row, caretIndex, xoffset+frame.width-1
                frame.x = xoffset
                xoffset += frame.width
                spacing = @style.spacing
                row.height = Math.max(row.height, frame.height)
            for frame in row.frames
                frame.y = yoffset + row.height / 2 - frame.height / 2
            @width = Math.max(xoffset + @style.rightPadding, @width)
            yoffset += row.height
            verticalSpacing = @style.verticalSpacing
            indent = @style.indent
        @height = yoffset + @style.bottomPadding
        for row in @rows
            if (i = @node.indexOf(row.rbreaker)) >= 0
                caretPush row, i, @width - @style.rightPadding - 1
        lastrow = @rows[@rows.length-1]
        caretPush lastrow, @node.length, @width - @style.rightPadding - 1
        return null

    paint: (bc) ->
        paintBackground bc, @
        bc.save()
        bc.translate(@x, @y)
        for frame in @frames
            frame.paint(bc)
        bc.restore()

    getPosition: () ->
        x = y = 0
        {x, y} = @parent.getPosition() if @parent?
        return {x:x+@x, y:y+@y}

    pick: (x, y) ->
        for frame in @frames
            result = frame.pick(x-@x, y-@y)
            return result if result?
        return @ if @x <= x < @x+@width and @y <= y < @y+@height
        return null

    nearest: (x, y) ->
        best = {dist: Infinity, frame:null}
        kx = x - clamp(x, @x, @x+@width)
        for row in @rows
            dy = y - clamp(y, @y+row.offset, @y+row.offset+row.height)
            for caret in row.carets
                dx = x - clamp(x, caret.left+@x, caret.right+@x)
                if dx*dx + dy*dy < best.dist
                    best.dist  = dx*dx + dy*dy
                    best.index = caret.index
                    best.frame = @
        for frame in @frames
            result = frame.nearest(x-@x, y-@y)
            best = result if result.dist < best.dist
        return best

    paintSelection: (bc, start, stop) ->
        {x, y} = @getPosition()
        for row in @rows
            ry = y + row.offset
            if start == stop
                for caret in row.carets
                    if caret.index == start
                        bc.fillRect caret.left + x, ry, caret.right-caret.left, row.height
            else
                first = null
                last = null
                for caret in row.carets
                    if start <= caret.index <= stop
                        first ?= caret
                        last = caret
                if last?
                    bc.fillRect first.right + x, ry, last.left-first.right, row.height

    find: (node) ->
        return @ if node == @node
        for frame in @frames
            result = frame.find node
            return result if result?
        return null

caretPush = (row, index, x) ->
    carets = row.carets
    lc = carets[carets.length-1]
    if carets.length == 0
        carets.push {index, left:x, right:x+1}
    else if lc.index == index
        lc.left = Math.min(lc.left, x)
        lc.right = Math.max(lc.right, x+1)
    else
        carets.push {index, left:x, right:x+1}
    return null

class TextFrame
    constructor: (@node, @style) ->
        @parent = null

    layout: (bc) ->
        @x = 0
        @y = 0
        setFont bc, @style
        @text  = @node.text
        @width = bc.measureText(@text).width
        @height = @style.fontSize
        @offsets = [0]
        for i in [1..@text.length]
            @offsets.push bc.measureText(@text[0...i]).width

    paint: (bc) ->
        paintBackground bc, @
        bc.textBaseline = "middle"
        setFont bc, @style
        bc.fillStyle = @style.color
        bc.fillText @text, @x, @y+@height/2, @width

    getPosition: () ->
        x = y = 0
        {x, y} = @parent.getPosition() if @parent?
        return {x:x+@x, y:y+@y}

    pick: (x, y) ->
        return null

    nearest: (x, y) ->
        dist  = Infinity
        index = 0
        k = 0
        for offset in @offsets
            d = x - offset-@x
            if d*d < dist
                index = k
                dist  = d*d
            k += 1
        dx = x - clamp(x, @x, @x+@width)
        dy = y - clamp(y, @y, @y+@height)
        return {dist: dx*dx+dy*dy, frame:@, index:index}

    paintSelection: (bc, start, stop) ->
        {x, y} = @getPosition()
        left  = @offsets[start] - 1
        right = @offsets[stop] + 1
        bc.fillRect(x+left, y, right - left, @height)

    find: (node) ->
        return @ if node == @node
        return null

clamp = (x, low, high) -> Math.max(low, Math.min(high, x))

class MarkFrame
    constructor: (@node, @style) ->
        @parent = null

    layout: (bc) ->
        @x = 0
        @y = 0
        setFont bc, @style
        @text = @node.label
        @width = bc.measureText(@text).width
        @height = @style.fontSize

    paint: (bc) ->
        paintBackground bc, @
        bc.textBaseline = "middle"
        setFont bc, @style
        bc.fillStyle = @style.color
        bc.fillText @text, @x, @y+@height/2, @width

    getPosition: () ->
        x = y = 0
        {x, y} = @parent.getPosition() if @parent?
        return {x:x+@x, y:y+@y}

    pick: (x, y) ->
        return @ if @x <= x < @x+@width and @y <= y < @y+@height
        return null

    nearest: (x, y) ->
        return {dist: Infinity, frame:null}

    find: (node) ->
        return @ if node == @node
        return null

class DecoFrame
    constructor: (@text, @style) ->
        @parent = null

    layout: (bc) ->
        @x = 0
        @y = 0
        setFont bc, @style
        @width = bc.measureText(@text).width
        @height = @style.fontSize

    paint: (bc) ->
        paintBackground bc, @
        bc.textBaseline = "middle"
        setFont bc, @style
        bc.fillStyle = @style.color
        bc.fillText @text, @x, @y+@height/2, @width

    getPosition: () ->
        x = y = 0
        {x, y} = @parent.getPosition() if @parent?
        return {x:x+@x, y:y+@y}

    pick: (x, y) ->
        return null

    nearest: (x, y) ->
        return {dist: Infinity, frame:null}

    find: (node) ->
        return null

paintBackground = (bc, frame) ->
    if frame.style.background?
        bc.fillStyle = frame.style.background
        bc.fillRect frame.x, frame.y, frame.width, frame.height
    if frame.style.border?
        bc.strokeStyle = frame.style.border
        bc.strokeRect frame.x, frame.y, frame.width, frame.height

setFont = (bc, style) ->
    bc.font = "#{style.fontSize}px #{style.fontName}"

window.newFrame = (node, style) ->
    return new MarkFrame(node, style) if isMark(node)
    return new TextFrame(node, style) if isText(node)
    return new ListFrame(node, style) if isList(node)
    throw "cannot frame #{node}"
window.newDeco = (text, style) ->
    return new DecoFrame(text, style)
