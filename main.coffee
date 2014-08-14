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
    mouse = mouseInput(canvas)
    window.model = model

    over = null

    #target = model.list[0]
    #target.selection = {start: 1, stop: 1}
    #model.selection = {start: 2, stop: 3}

    canvas.addEventListener 'mousedown', () ->
        if over?
            lb = listbuffer(cr(), over)
            lb.link = over
            model.put model.length, lb
        else
            lb = listbuffer(cr(), text("LISP"))
            model.put model.length, lb

    draw = () ->
        bc.fillStyle = "#aaa"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        bc.textBaseline = "middle"
        model.layout(bc)
        model.x = 50
        model.y = 50
        over = model.mousemotion(mouse.point...)
        model.draw(bc)

        bc.fillText "click the screen or contents to test PUT -commands", 50, 10

        requestAnimationFrame draw

    drawBox = (x, y, w, h) ->
        bc.beginPath()
        bc.rect(x, y, w, h)
        bc.fill()
        bc.stroke()

    draw()
