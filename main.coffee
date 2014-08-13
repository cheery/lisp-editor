window.addEventListener 'load', () ->
    canvas = autoResize document.getElementById('editor')
    bc = canvas.getContext '2d'

    model = list(
        text("define"), list(text("factorial"), text("n")), cr(),
        list(
            text("if"), list(text("="), text("n"), text("0")), text("1"), cr(),
            list(text("*"), text("n"), list(text("factorial"), list(text("-"), text("n"), text("1"))))
        )
    )
    window.model = model

    draw = () ->
        bc.fillStyle = "#aaa"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        bc.textBaseline = "middle"
        model.layout(bc)
        model.x = 50
        model.y = 50
        model.draw(bc)

        requestAnimationFrame draw

    drawBox = (x, y, w, h) ->
        bc.beginPath()
        bc.rect(x, y, w, h)
        bc.fill()
        bc.stroke()


    draw()

class TextNode
    constructor: (@text) ->
        @type = 'text'

    layout: (bc) ->
        bc.font = "16px sans-serif"
        @x = 0
        @y = 0
        @width  = bc.measureText(@text).width
        @height = 16

    draw: (bc) ->
        bc.font = "16px sans-serif"
        bc.fillStyle = "black"
        bc.fillText @text, @x, @y+@height/2, @width

padding = 8

class ListNode
    constructor: (@list) ->
        @type = 'list'

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
        bc.fillRect   @x, @y, @width, @height
        bc.strokeRect @x, @y, @width, @height
        bc.save()
        bc.translate(@x, @y)
        for item in @list
            item.draw(bc)
        bc.restore()

class Carriage
    constructor: (@list) ->
        @type = 'cr'

    layout: (bc) ->
        @x = 0
        @y = 0
        @height = 0
        @width  = 0

    draw: (bc) ->

cr = () -> new Carriage()

text = (text) -> new TextNode(text)
list = (data...) -> new ListNode(data)
