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

    selection = textright leftSelection model
    selection.mark()


    #target = model.list[0]
    #target.selection = {start: 1, stop: 1}
    #model.selection = {start: 2, stop: 3}
    selectMode = (keyCode, text) ->
        selection.unmark()
        if text == 'l'
            if selection.head < selection.target.length and selection.target.type == 'text'
                selection.update(selection.head+1, selection.head+1)
            else
                selection = textright travelRight selection
        if text == 'w'
            selection = textright travelRight selection
        if text == 'e'
            if selection.target.type != 'text' or selection.head == selection.target.length
                selection = textright travelRight selection
            if selection.target.type == 'text'
                selection.update(selection.target.length, selection.target.length)
        if text == 'h'
            if 0 < selection.head and selection.target.type == 'text'
                selection.update(selection.head-1, selection.head-1)
            else
                selection = textleft travelLeft selection
        if text == 'b'
            if selection.target.type != 'text' or selection.head == 0
                selection = textleft travelLeft selection
            if selection.target.type == 'text'
                selection.update(0, 0)
        selection.mark()

    mode = selectMode
    keyboardEvents canvas, (keyCode, text) ->
        mode(keyCode, text)

#    canvas.addEventListener 'mousedown', () ->
#        if over?
#            lb = listbuffer(cr(), over)
#            lb.link = over
#            model.put model.length, lb
#        else
#            lb = listbuffer(cr(), text("LISP"))
#            model.put model.length, lb

    draw = () ->
        bc.fillStyle = "#aaa"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        bc.textBaseline = "middle"
        model.layout(bc)
        model.x = 50
        model.y = 50
        over = model.mousemotion(mouse.point...)
        model.draw(bc)

        bc.fillText "press (h,l,w,e,b) -keys to try basic motions", 50, 10

        requestAnimationFrame draw

    drawBox = (x, y, w, h) ->
        bc.beginPath()
        bc.rect(x, y, w, h)
        bc.fill()
        bc.stroke()

    draw()

class Selection
    constructor: (@target, @head, @tail) ->
        @update(@head, @tail)

    update: (@head, @tail) ->
        @start = Math.min(@head, @tail)
        @stop  = Math.max(@head, @tail)

    mark: () ->
        @target.selection = @

    unmark: () ->
        @target.selection = null

leftSelection = (target) ->
    return new Selection(target, 0, 0)

rightSelection = (target) ->
    return new Selection(target, target.length, target.length)

textleft = (selection) ->
    {target, start, stop} = selection
    if target.type != 'text' and 0 < start
        node = target.list[start-1]
        return new Selection(node, node.length, node.length) if node.type == 'text'
    return selection

textright = (selection) ->
    {target, start, stop} = selection
    if target.type != 'text' and stop < target.length
        node = target.list[stop]
        return new Selection(node, 0, 0) if node.type == 'text'
    return selection

travelLeft = (selection) ->
    {target, head} = selection
    if target.type == 'text'
        {start, target} = target.getRange()
        return travelLeft new Selection(target, start, start)
    if target.type == 'list'
        if 0 < head
            node = target.list[head-1]
            if node.type == 'list' or node.type == 'text'
                return rightSelection node
            return new Selection(target, head-1, head-1)
        else if target.parent?
            {start, target} = target.getRange()
            return new Selection(target, start, start)
    return selection

travelRight = (selection) ->
    {target, head} = selection
    if target.type == 'text'
        {stop, target} = target.getRange()
        return travelRight new Selection(target, stop, stop)
    if target.type == 'list'
        if head < target.length
            node = target.list[head]
            if node.type == 'list' or node.type == 'text'
                return leftSelection node
            return new Selection(target, head+1, head+1)
        else if target.parent?
            {stop, target} = target.getRange()
            return new Selection(target, stop, stop)
    return selection
