{bc, teh} = env
{px} = teh

isFunction = (obj) -> obj instanceof Function

console.log isFunction env.teh.Box(10, 10, 10)

fsz = 16

textbox = (bc, text) ->
    font = "#{fsz}px sans-serif"
    bc.font = font
    width = bc.measureText(text).width
    box = teh.Box(width, 3/4*fsz, 1/4*fsz)
    box.paint = (bc) ->
        bc.font = font
        bc.fillText(text, @x, @y+@shift)
    return box

black = () ->
    box = teh.Box(fsz, 3/4*fsz, 1/4*fsz)
    box.paint = (bc) ->
        bc.fillRect @x, @y-@height, @width, @height+@depth
    return box

vspace = () ->
    glue = teh.Glue(fsz * 0.5)
    return glue

hrule = () ->
    glue = teh.Glue(fsz * 0.5)
    glue.paint = (bc, vertical) ->
        {width, height, depth} = @computeFill(vertical)
        bc.fillRect @x, @y-height+3, width, 1
    return glue

shifted = (box) ->
    box.shift += fsz * 0.25
    box.width -= 2
    return box

narrowed = (box) ->
    box.width -= 2
    return box

env.draw = () ->
    env.clearScreen()

    list = [
        teh.hbox [
            textbox(bc, "The power of ")
            narrowed textbox(bc, "T")
            shifted textbox(bc, "E")
            textbox(bc, "X-style layouting.")
        ]
        vspace()
        teh.hbox [
            textbox(bc, "Inside the ")
            teh.vbox [
                textbox(bc, "visual")
                textbox(bc, "pisual")
                textbox(bc, "programming")
                textbox(bc, "editor")
            ]
        ]
        vspace()
        teh.hbox [
            black()
            teh.Glue(10)
            textbox(bc, "hubbbububub")
            teh.Glue(10)
            teh.vbox [
                textbox(bc, "bakabaka")
                hline = hrule()
                textbox(bc, "bak")
            ], () -> hline.y + fsz*0.5
        ]
    ]

    box = teh.vbox(list, teh.alignTop)
    box.x = 10
    box.y = 10

    #box.paintMetrics(bc)
    box.paint(bc)



    window.requestAnimationFrame env.draw
