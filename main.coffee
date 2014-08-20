window.addEventListener 'load', () ->
    canvas = autoResize document.getElementById('editor')
    bc = canvas.getContext '2d'

    command = list()
    commandSelection = null

    model = list(
        labelled 'define', list(
            list(text("factorial"), text("n")), cr(),
            labelled 'cond', list(
                list(
                    list(text("="), text("n"), text("0")), cr(),
                    text("1"))
                cr()
                list(cr(),
                    list(text("n"), text("*"), list(text("factorial"), list(text("n"), text("-"), text("1")))))
            )
        )
    )
    mouse = mouseInput(canvas)
    window.model = model

    over = null
    mode = null

    selection = textright leftSelection model

    insertMode = (keyCode, txt) ->
        if keyCode == 27
            mode = selectMode
        else if keyCode == 13
            insertCr()
        else if txt == " "
            insertSpace()
        else if txt == "("
            insertBox()
        else if txt == ")"
            outOfBox()
        else if txt == ";"
            relabelNode()
        else if txt.length > 0
            insertCharacter(txt)
        else if keyCode == 8
            selection = delLeft(selection)
        else if keyCode == 46
            selection = delRight(selection)
        else
            console.log keyCode
    insertMode.tag = "insert"

    commandMode = (keyCode, txt) ->
        if selection.target.type == 'text'
            toplevel = not selection.target.parent.parent?
        else
            toplevel = selection.target.parent?
        if keyCode == 27
            selection = commandSelection
            commandSelection = null
            mode = selectMode
        else if keyCode == 13 and toplevel
            selection = commandSelection
            commandSelection = null
            mode = selectMode
        else
            insertMode keyCode, txt

    relabelNode = () ->
        {target} = selection
        if target.type == "text"
            label = target.text
            {target, start, stop} = target.getRange()
            target.kill(start, stop)
            target.label = label
            selection = new Selection(target, start, start)
        else
            target.label = null

    delLeft = (selection) ->
        {target, head} = selection
        if target.type == 'text'
            if head > 0
                target.kill(head-1, head)
                if target.length == 0
                    {target, start, stop} = target.getRange()
                    target.kill(start, stop)
                    return new Selection(target, start, start)
                return new Selection(target, head-1, head-1)
            else
                {target: node, start, stop} = target.getRange()
                if start > 0
                    before = node.get start-1
                    if before.type == 'text'
                        textnode = text(before.text + target.text)
                        index = before.length
                        node.kill(start-1, stop)
                        node.put(start, listbuffer(textnode))
                        return new Selection(textnode, index, index)
                return delLeft(new Selection(node, 0, 0))
        if target.type == 'list'
            if head > 0
                before = target.get head-1
                if before.type == 'list'
                    return new Selection(before, before.length, before.length)
                if before.type == 'text'
                    return delLeft new Selection(before, before.length, before.length)
                target.kill(head-1, head)
                return new Selection(target, head-1, head-1)
            else if target.parent?
                {target:node, start, stop} = target.getRange()
                if target.length == 0
                    node.kill(start, stop)
                return new Selection(node, start, start)
        return selection

    delRight = (selection) ->
        {target, head} = selection
        if target.type == 'text'
            if head < target.length
                target.kill(head, head+1)
                if target.length == 0
                    {target, start, stop} = target.getRange()
                    target.kill(start, stop)
                    return new Selection(target, start, start)
                return new Selection(target, head, head)
            else
                {target: node, start, stop} = target.getRange()
                if stop < node.length
                    ahead = node.get stop
                    if ahead.type == 'text'
                        textnode = text(target.text + ahead.text)
                        index = target.length
                        node.kill(start, stop+1)
                        node.put(start, listbuffer(textnode))
                        return new Selection(textnode, index, index)
                return delRight(new Selection(node, stop, stop))
        if target.type == 'list'
            if head < target.length
                ahead = target.get head
                if ahead.type == 'list'
                    return new Selection(ahead, 0, 0)
                if ahead.type == 'text'
                    return delRight new Selection(ahead, 0, 0)
                target.kill(head, head+1)
                return new Selection(target, head, head)
            else if target.parent?
                {target:node, start, stop} = target.getRange()
                if target.length == 0
                    node.kill(start, stop)
                    return new Selection(node, start, start)
                return new Selection(node, stop, stop)
        return selection

    copybuffer = null
    visualMode = (keyCode, text) ->
        if keyCode == 27
            mode = selectMode
            selection.update(selection.head, selection.head, false)
        else if text == 'h'
            {target, head, tail, inclusive} = selection
            if head > 0
                selection.update(head-1, tail, inclusive)
            else
                {target, start} = target.getRange()
                selection = new Selection target, start, start, true
        else if text == 'l'
            {target, head, tail, inclusive} = selection
            if head < target.length - 1
                selection.update(head+1, tail, inclusive)
            else
                {target, start} = target.getRange()
                selection = new Selection target, start, start, true
        else if text == 'v' and selection.target.parent?
            {target, start} = selection.target.getRange()
            selection = new Selection target, start, start, true
        else if text == 'd'
            {target, start, stop} = selection
            copybuffer = target.kill(start, stop)
            selection.update(start, start, false)
            mode = selectMode
        else if text == 'y'
            {target, start, stop} = selection
            copybuffer = target.yank(start, stop)
            selection.update(start, start, false)
            mode = selectMode

    visualMode.tag = "visual"

    #target.selection = {start: 1, stop: 1}
    #model.selection = {start: 2, stop: 3}
    selectMode = (keyCode, txt) ->
        if txt == ':'
            commandSelection = selection
            command = list()
            selection = new Selection(command, 0, 0)
            mode = commandMode
        if txt == ' ' and selection.target.type == 'text'
            if selection.head == selection.target.length
                {target, stop} = selection.target.getRange()
                selection = new Selection target, stop, stop
            else if selection.head == 0
                {target, start} = selection.target.getRange()
                selection = new Selection target, start, start
        if txt == 'i'
            mode = insertMode
        if txt == 'l'
            selection = stepRight(selection)
        if txt == 'w'
            selection = textright travelRight selection
        if txt == 'e'
            if selection.target.type != 'text' or selection.head == selection.target.length
                selection = textright travelRight selection
            if selection.target.type == 'text'
                selection.update(selection.target.length, selection.target.length)
        if txt == 'h'
            selection = stepLeft(selection)
        if txt == 'b'
            if selection.target.type != 'text' or selection.head == 0
                selection = textleft travelLeft selection
            if selection.target.type == 'text'
                selection.update(0, 0)
        if txt == 'v'
            mode = visualMode
            selection.update(selection.head, selection.tail, true)
        if txt == 'P' and copybuffer?
            {target, head} = selection
            switch nodeType(target)
                when "text"
                    if copybuffer.type == 'textbuffer'
                        target.put(head, copybuffer)
                    if copybuffer.type == 'listbuffer'
                        {target, start} = target.getRange()
                        target.put(start, copybuffer)
                when "list"
                    if copybuffer.type == 'textbuffer'
                        buf = listbuffer(text(copybuffer.text))
                        target.put(head, buf)
                    if copybuffer.type == 'listbuffer'
                        target.put(head, copybuffer)
        if txt == 'p' and copybuffer?
            {target, head} = selection
            switch nodeType(target)
                when "text"
                    if copybuffer.type == 'textbuffer'
                        target.put(head, copybuffer)
                    if copybuffer.type == 'listbuffer'
                        {target, stop} = target.getRange()
                        target.put(stop, copybuffer)
                when "list"
                    if copybuffer.type == 'textbuffer'
                        target.put(head, listbuffer(text(copybuffer.text)))
                    if copybuffer.type == 'listbuffer'
                        target.put(head, copybuffer)
    selectMode.tag = "select"

    stepLeft = (selection) ->
        if 0 < selection.head and selection.target.type == 'text'
            selection = new Selection(selection.target, selection.head-1, selection.head-1)
        else
            selection = textleft travelLeft selection
        return selection

    stepRight = (selection) ->
        if selection.head < selection.target.length and selection.target.type == 'text'
            selection = new Selection(selection.target, selection.head+1, selection.head+1)
        else
            selection = textright travelRight selection
        return selection

    insertCr = () ->
        if selection.target.type == 'text'
            if 0 < selection.head < selection.target.length
                node_split selection.target, selection.head
                {target, stop} = selection.target.getRange()
                selection = new Selection(target, stop, stop)
            else if selection.head == selection.target.length
                {target, stop} = selection.target.getRange()
                selection = new Selection(target, stop, stop)
            else if selection.head == 0
                {target, start} = selection.target.getRange()
                selection = new Selection(target, start, start)
        selection.target.put selection.head, listbuffer(cr())
        head = selection.head + 1
        selection.update(head, head)
        return selection

    insertSpace = () ->
        if selection.target.type == 'text'
            {head, target} = selection
            if head == target.length
                {target, stop} = target.getRange()
                selection = new Selection(target, stop, stop)
            else if head == 0
                {target, start} = target.getRange()
                selection = new Selection(target, start, start)
            else
                selection = node_split target, head
        return selection

    insertBox = () ->
        if selection.target.type == 'text'
            {head, target} = selection
            if head == target.length
                {target, stop} = target.getRange()
                selection = new Selection(target, stop, stop)
            else if head == 0
                {target, start} = target.getRange()
                selection = new Selection(target, start, start)
            else
                selection = node_split target, head
                {target, stop} = target.getRange()
                selection = new Selection(target, stop, stop)
        obj = list()
        selection.target.put selection.head, listbuffer(obj)
        selection.target = obj
        selection.update(0, 0)
        return selection

    outOfBox = () ->
        if selection.target.type == 'text'
            {target} = selection.target.getRange()
        else
            {target} = selection
        if (range = target.getRange())?
            selection = new Selection(range.target, range.stop, range.stop)
        return selection

    insertCharacter = (txt) ->
        switch nodeType(selection.target)
            when 'text'
                tb = textbuffer(txt)
                selection.target.put selection.head, tb
                head = selection.head+txt.length
                selection.update(head, head)
            when 'list'
                tnode = text(txt)
                lb = listbuffer(tnode)
                selection.target.put selection.head, lb
                selection = new Selection(tnode, txt.length, txt.length)
        return selection

    node_split = (target, index) ->
        node = text(target.kill(index, target.length).text)
        {target, stop} = target.getRange()
        target.put stop, listbuffer(node)
        return new Selection(node, 0, 0)

    mode = selectMode
    keyboardEvents canvas, (keyCode, text) ->
        mode(keyCode, text)

    canvas.addEventListener 'mousedown', () ->
        if over?
            selection = new Selection over, over.hoverIndex, over.hoverIndex
            commandSelection = null
            mode = selectMode

    draw = () ->
        bc.fillStyle = "#aaa"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        bc.textBaseline = "middle"
        model.layout(bc)
        model.x = 50
        model.y = 50
        over = model.mousemotion(mouse.point...)
        model.draw(bc)

        if commandSelection
            command.layout(bc)
            command.x = 50
            command.y = canvas.height - command.height
            command.draw(bc)
            selection.draw(bc)
        else
            selection.draw(bc)
            bc.fillStyle = "white"
            bc.fillText "-- " + mode.tag + " --", 50, canvas.height - 10
        #bc.fillText "There is one special form here already (cond, marked in yellow),", 50, 10
        #bc.fillText "unfortunately no insertion method for them yet.", 50, 30


        requestAnimationFrame draw

    drawBox = (x, y, w, h) ->
        bc.beginPath()
        bc.rect(x, y, w, h)
        bc.fill()
        bc.stroke()

    draw()

class Selection
    constructor: (@target, @head, @tail, @inclusive=false) ->
        @update(@head, @tail, @inclusive)

    update: (@head, @tail, @inclusive=false) ->
        if @inclusive
            @head = Math.max(0, Math.min(@head, @target.length-1))
            @tail = Math.max(0, Math.min(@tail, @target.length-1))
        else
            @head = Math.max(0, Math.min(@head, @target.length))
            @tail = Math.max(0, Math.min(@tail, @target.length))
        @start = Math.min(@head, @tail)
        @stop  = Math.max(@head+@inclusive, @tail+@inclusive)

    draw: (bc) ->
        @target.drawSelection bc, @start, @stop


leftSelection = (target) ->
    return new Selection(target, 0, 0)

rightSelection = (target) ->
    return new Selection(target, target.length, target.length)

textleft = (selection) ->
    {target, start, stop} = selection
    if target.type != 'text' and 0 < start
        node = target.get start-1
        return new Selection(node, node.length, node.length) if node.type == 'text'
    return selection

textright = (selection) ->
    {target, start, stop} = selection
    if target.type != 'text' and stop < target.length
        node = target.get stop
        return new Selection(node, 0, 0) if node.type == 'text'
    return selection

travelLeft = (selection) ->
    {target, head} = selection
    if target.type == 'text'
        {start, target} = target.getRange()
        return travelLeft new Selection(target, start, start)
    if target.type == 'list'
        if 0 < head
            node = target.get head-1
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
            node = target.get head
            if node.type == 'list' or node.type == 'text'
                return leftSelection node
            return new Selection(target, head+1, head+1)
        else if target.parent?
            {stop, target} = target.getRange()
            return new Selection(target, stop, stop)
    return selection
