defaultStyle = {
    fontName: "sans-serif"
    fontSize: 16
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    spacing: 5
    indent: 10
    verticalSpacing: 0
    color: "black"
    selection: "blue"
    #background: "green"
    #border: "red"
}

buildStyle = (parent, style) ->
    for name, value of parent
        style[name] ?= value
    return style

labelStyle = buildStyle defaultStyle, {
    color: "purple"
    fontSize: 12
}

condStyle = buildStyle defaultStyle, {
    indent: 0
    selection: "yellow"
}

addFrame = (container, node) ->
    if isMark(node, 'cr')
        return container.newline(node)
    #    container.push frame = newFrame node, container.style
    if isList(node, 'cond')
        container.push frame = newFrame node, condStyle
        first = true
        for item in node.list
            frame.newline() unless first
            if isList(item, 'else')
                row = newFrame item, defaultStyle
                row.push newDeco("else", labelStyle)
                for subitem in item.list
                    addFrame row, subitem
            else
                row = newFrame item, defaultStyle
                row.push newDeco("else", labelStyle) unless first
                row.push newDeco("if", labelStyle)
                for subitem in item.list
                    addFrame row, subitem
            frame.push row
            first = false
    else if isList(node, 'infix')
        container.push frame = newFrame node, buildStyle defaultStyle, {
            selection: "green"
        }
        #frame.push newDeco("{", labelStyle)
        addFrame frame, item for item in node.list
        #frame.push newDeco("}", labelStyle)
    else if isList(node)
        container.push frame = newFrame node, buildStyle defaultStyle, {
            selection: "blue"
        }
        if node.label?
            frame.push newDeco(node.label, labelStyle)
        for item in node.list
            addFrame(frame, item)
    else if isText(node, 'int')
        container.push frame = newFrame node, buildStyle container.style, {
            color: "blue"
        }
    else
        container.push frame = newFrame node, container.style
    return null

window.addEventListener 'load', () ->
    canvas = autoResize document.getElementById('editor')
    bc = canvas.getContext '2d'
    mouse = mouseInput(canvas)

    root = newList([
        newList([
            newList([
                newText("square")
                newText("x")
            ])
            newMark('cr')
            newList([
                newText("x")
                newText("*")
                newText("x")
            ], 'infix')
        ], 'define')
        newList([
            newList([
                newText("factorial")
                newText("n")
            ])
            newMark('cr')
            newList([
                newList([
                    newList([
                        newText("n")
                        newText("=")
                        newText("1", "int")
                    ], 'infix')
                    newMark("cr")
                    newText("1", "int")
                ])
                newList([
                    newList([
                        newText("n")
                        newText("=")
                        newText("0", "int")
                    ], 'infix')
                    newMark("cr")
                    newText("1", "int")
                ])
                newList([
                    newMark("cr")
                    newList([
                        newText("n")
                        newText("*")
                        newList([
                            newText("factorial")
                            newList([
                                newText("n")
                                newText("-")
                                newText("1", "int")
                            ], 'infix')
                        ])
                    ], 'infix')
                ], 'else')
            ], 'cond')
        ], 'define')
    ])

    cursor = {index:0, node:root}
    

    frame = newFrame root, buildStyle defaultStyle, {
        indent: 0
        verticalSpacing: 25
    }
    first = true
    for node in frame.node.list
        frame.newline() unless first
        addFrame(frame, node)
        first = false

    canvas.addEventListener 'click', (ev) ->
        ev.preventDefault()
        if (near = frame.nearest(mouse.point...))?
            cursor = {index:near.index, node:near.frame.node}

#    mode = selectMode
    keyboardEvents canvas, (keyCode, text) ->
        code = if text == "" then keyCode else text
        console.log code
#        mode(keyCode, text)


    draw = () ->
        bc.fillStyle = "#ccc"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        frame.layout(bc)
        frame.x = 50
        frame.y = 50
        frame.paint(bc)

        if (near = frame.nearest(mouse.point...))?
            drawSelection(bc, near.frame, near.index, near.index, "black")

        if cursor?
            cframe = frame.find cursor.node
            if cframe?
                drawSelection(bc, cframe, cursor.index, cursor.index, "blue")

        bc.font = "12px sans-serif"
        bc.fillStyle = 'black'
        bc.fillRect(0, 0, canvas.width, 16)
        bc.fillStyle = 'white'
        bc.fillText " index [] ", 0, 11

        jk = frame.y + frame.height + 12
        bc.fillStyle = 'black'
        bc.fillText " I already published the layout upgrade", 0, jk
        bc.fillText " But the input processing requires bit more work.", 0, jk + 12
        bc.fillText " Please have patience with me. The editor won't recognise input for few days.", 0, jk + 24

        bc.fillRect(0, canvas.height-16, canvas.width, 16)
        bc.fillStyle = 'white'
        bc.fillText " -- select --", 0, canvas.height - 5

        requestAnimationFrame draw
    draw()

drawSelection = (bc, frame, start, stop, style) ->
    bc.globalAlpha = 0.1
    parent = frame.parent
    while parent?
        bc.strokeStyle = parent.style.selection
        {x, y} = parent.getPosition()
        bc.strokeRect(x, y, parent.width, parent.height)
        parent = parent.parent
    bc.globalAlpha = 0.5
    bc.strokeStyle = style
    bc.fillStyle = style
    frame.paintSelection(bc, start, stop)
    bc.globalAlpha = 1.0

#    selection = textright leftSelection model
#
#    mouse = mouseInput(canvas)
#    window.model = model
#
#    over = null
#    mode = null
#
#    loadFile = (path) ->
#        fs.load path, (doc) ->
#            currentdoc = doc
#            model = doc.node
#            selection = textright leftSelection model
#
#    fs = new LispFS () ->
#        fs.load "index", (doc) ->
#            currentdoc = doc
#            unless doc.ent?
#                doc.replace model
#                fs.store doc
#            else
#                model = doc.node
#                selection = textright leftSelection model
#
#    submitCommand = () ->
#        return if command.length < 1
#        node = command.get(0)
#        if isSymbol(node, "edit") or isSymbol(node, "e")
#            arg = command.get(1)
#            if nodeType(arg) == 'text'
#                return loadFile(arg.text)
#        if isSymbol(node, "write") or isSymbol(node, "w")
#            return fs.store(currentdoc)
#        console.log 'unrecognised command...', node
#
#    isSymbol = (node, txt) ->
#        return node.type == 'text' and node.text == txt
#
#    inString = (selection) ->
#        return selection.target.type == "text" and selection.target.label == "string"
#
#    insertMode = (keyCode, txt) ->
#        if keyCode == 27
#            mode = selectMode
#        else if keyCode == 13 and not inString(selection)
#            insertCr()
#        else if txt == '"'
#            insertString()
#        else if txt == " " and not inString(selection)
#            insertSpace()
#        else if txt == "(" and not inString(selection)
#            insertBox()
#        else if txt == ")" and not inString(selection)
#            outOfBox()
#        else if txt == ";" and not inString(selection)
#            relabelNode()
#        else if txt.length > 0
#            insertCharacter(txt)
#        else if keyCode == 8
#            selection = delLeft(selection)
#        else if keyCode == 46
#            selection = delRight(selection)
#        else
#            console.log keyCode
#    insertMode.tag = "insert"
#
#    commandMode = (keyCode, txt) ->
#        if selection.target.type == 'text'
#            toplevel = not selection.target.parent.parent?
#        else
#            toplevel = selection.target.parent?
#        if keyCode == 27
#            selection = commandSelection
#            commandSelection = null
#            mode = selectMode
#        else if keyCode == 13 and toplevel
#            selection = commandSelection
#            commandSelection = null
#            mode = selectMode
#            submitCommand()
#        else
#            insertMode keyCode, txt
#
#    relabelNode = () ->
#        {target} = selection
#        if target.type == "text"
#            label = target.text
#            {target, start, stop} = target.getRange()
#            target.kill(start, stop)
#            target.label = label
#            selection = new Selection(target, start, start)
#        else
#            target.label = null
#
#    delLeft = (selection) ->
#        {target, head} = selection
#        if target.type == 'text'
#            if head > 0
#                target.kill(head-1, head)
#                if target.length == 0
#                    {target, start, stop} = target.getRange()
#                    target.kill(start, stop)
#                    return new Selection(target, start, start)
#                return new Selection(target, head-1, head-1)
#            else
#                {target: node, start, stop} = target.getRange()
#                if start > 0
#                    before = node.get start-1
#                    if before.type == 'text'
#                        textnode = text(before.text + target.text)
#                        index = before.length
#                        node.kill(start-1, stop)
#                        node.put(start, listbuffer(textnode))
#                        return new Selection(textnode, index, index)
#                return delLeft(new Selection(node, 0, 0))
#        if target.type == 'list'
#            if head > 0
#                before = target.get head-1
#                if before.type == 'list'
#                    return new Selection(before, before.length, before.length)
#                if before.type == 'text'
#                    return delLeft new Selection(before, before.length, before.length)
#                target.kill(head-1, head)
#                return new Selection(target, head-1, head-1)
#            else if target.parent?
#                {target:node, start, stop} = target.getRange()
#                if target.length == 0
#                    node.kill(start, stop)
#                return new Selection(node, start, start)
#        return selection
#
#    delRight = (selection) ->
#        {target, head} = selection
#        if target.type == 'text'
#            if head < target.length
#                target.kill(head, head+1)
#                if target.length == 0
#                    {target, start, stop} = target.getRange()
#                    target.kill(start, stop)
#                    return new Selection(target, start, start)
#                return new Selection(target, head, head)
#            else
#                {target: node, start, stop} = target.getRange()
#                if stop < node.length
#                    ahead = node.get stop
#                    if ahead.type == 'text'
#                        textnode = text(target.text + ahead.text)
#                        index = target.length
#                        node.kill(start, stop+1)
#                        node.put(start, listbuffer(textnode))
#                        return new Selection(textnode, index, index)
#                return delRight(new Selection(node, stop, stop))
#        if target.type == 'list'
#            if head < target.length
#                ahead = target.get head
#                if ahead.type == 'list'
#                    return new Selection(ahead, 0, 0)
#                if ahead.type == 'text'
#                    return delRight new Selection(ahead, 0, 0)
#                target.kill(head, head+1)
#                return new Selection(target, head, head)
#            else if target.parent?
#                {target:node, start, stop} = target.getRange()
#                if target.length == 0
#                    node.kill(start, stop)
#                    return new Selection(node, start, start)
#                return new Selection(node, stop, stop)
#        return selection
#
#    copybuffer = null
#    visualMode = (keyCode, text) ->
#        if keyCode == 27
#            mode = selectMode
#            selection.update(selection.head, selection.head, false)
#        else if text == 'h'
#            {target, head, tail, inclusive} = selection
#            if head > 0
#                selection.update(head-1, tail, inclusive)
#            else
#                {target, start} = target.getRange()
#                selection = new Selection target, start, start, true
#        else if text == 'l'
#            {target, head, tail, inclusive} = selection
#            if head < target.length - 1
#                selection.update(head+1, tail, inclusive)
#            else
#                {target, start} = target.getRange()
#                selection = new Selection target, start, start, true
#        else if text == 'v' and selection.target.parent?
#            {target, start} = selection.target.getRange()
#            selection = new Selection target, start, start, true
#        else if text == 'd'
#            {target, start, stop} = selection
#            copybuffer = target.kill(start, stop)
#            selection.update(start, start, false)
#            mode = selectMode
#        else if text == 'y'
#            {target, start, stop} = selection
#            copybuffer = target.yank(start, stop)
#            selection.update(start, start, false)
#            mode = selectMode
#
#    visualMode.tag = "visual"
#
#    #target.selection = {start: 1, stop: 1}
#    #model.selection = {start: 2, stop: 3}
#    selectMode = (keyCode, txt) ->
#        if txt == ':'
#            commandSelection = selection
#            command = list()
#            selection = new Selection(command, 0, 0)
#            mode = commandMode
#        if txt == ' ' and selection.target.type == 'text'
#            if selection.head == selection.target.length
#                {target, stop} = selection.target.getRange()
#                selection = new Selection target, stop, stop
#            else if selection.head == 0
#                {target, start} = selection.target.getRange()
#                selection = new Selection target, start, start
#        if txt == 'i'
#            mode = insertMode
#        if txt == 'l'
#            selection = stepRight(selection)
#        if txt == 'w'
#            selection = textright travelRight selection
#        if txt == 'e'
#            if selection.target.type != 'text' or selection.head == selection.target.length
#                selection = textright travelRight selection
#            if selection.target.type == 'text'
#                selection.update(selection.target.length, selection.target.length)
#        if txt == 'h'
#            selection = stepLeft(selection)
#        if txt == 'b'
#            if selection.target.type != 'text' or selection.head == 0
#                selection = textleft travelLeft selection
#            if selection.target.type == 'text'
#                selection.update(0, 0)
#        if txt == 'v'
#            mode = visualMode
#            selection.update(selection.head, selection.tail, true)
#        if txt == 'P' and copybuffer?
#            {target, head} = selection
#            switch nodeType(target)
#                when "text"
#                    if copybuffer.type == 'textbuffer'
#                        target.put(head, copybuffer)
#                    if copybuffer.type == 'listbuffer'
#                        {target, start} = target.getRange()
#                        target.put(start, copybuffer)
#                when "list"
#                    if copybuffer.type == 'textbuffer'
#                        buf = listbuffer(text(copybuffer.text))
#                        target.put(head, buf)
#                    if copybuffer.type == 'listbuffer'
#                        target.put(head, copybuffer)
#        if txt == 'p' and copybuffer?
#            {target, head} = selection
#            switch nodeType(target)
#                when "text"
#                    if copybuffer.type == 'textbuffer'
#                        target.put(head, copybuffer)
#                    if copybuffer.type == 'listbuffer'
#                        {target, stop} = target.getRange()
#                        target.put(stop, copybuffer)
#                when "list"
#                    if copybuffer.type == 'textbuffer'
#                        target.put(head, listbuffer(text(copybuffer.text)))
#                    if copybuffer.type == 'listbuffer'
#                        target.put(head, copybuffer)
#        if txt == '%'
#            window.evaluateDocument(currentdoc)
#    selectMode.tag = "select"
#
#    stepLeft = (selection) ->
#        if 0 < selection.head and selection.target.type == 'text'
#            selection = new Selection(selection.target, selection.head-1, selection.head-1)
#        else
#            selection = textleft travelLeft selection
#        return selection
#
#    stepRight = (selection) ->
#        if selection.head < selection.target.length and selection.target.type == 'text'
#            selection = new Selection(selection.target, selection.head+1, selection.head+1)
#        else
#            selection = textright travelRight selection
#        return selection
#
#    insertCr = () ->
#        if selection.target.type == 'text'
#            if 0 < selection.head < selection.target.length
#                node_split selection.target, selection.head
#                {target, stop} = selection.target.getRange()
#                selection = new Selection(target, stop, stop)
#            else if selection.head == selection.target.length
#                {target, stop} = selection.target.getRange()
#                selection = new Selection(target, stop, stop)
#            else if selection.head == 0
#                {target, start} = selection.target.getRange()
#                selection = new Selection(target, start, start)
#        selection.target.put selection.head, listbuffer(cr())
#        head = selection.head + 1
#        selection.update(head, head)
#        return selection
#
#    insertSpace = () ->
#        if selection.target.type == 'text'
#            {head, target} = selection
#            if head == target.length
#                {target, stop} = target.getRange()
#                selection = new Selection(target, stop, stop)
#            else if head == 0
#                {target, start} = target.getRange()
#                selection = new Selection(target, start, start)
#            else
#                selection = node_split target, head
#        return selection
#
#    insertBox = () ->
#        if selection.target.type == 'text'
#            {head, target} = selection
#            if head == target.length
#                {target, stop} = target.getRange()
#                selection = new Selection(target, stop, stop)
#            else if head == 0
#                {target, start} = target.getRange()
#                selection = new Selection(target, start, start)
#            else
#                selection = node_split target, head
#                {target, stop} = target.getRange()
#                selection = new Selection(target, stop, stop)
#        obj = list()
#        selection.target.put selection.head, listbuffer(obj)
#        selection.target = obj
#        selection.update(0, 0)
#        return selection
#
#    outOfBox = () ->
#        if selection.target.type == 'text'
#            {target} = selection.target.getRange()
#        else
#            {target} = selection
#        if (range = target.getRange())?
#            selection = new Selection(range.target, range.stop, range.stop)
#        return selection
#
#    insertString = () ->
#        switch nodeType(selection.target)
#            when 'text'
#                if selection.target.label == "string"
#                    {start, stop, target} = selection.target.getRange()
#                    selection = new Selection(target, stop, stop)
#                else
#                    labelled "string", selection.target
#            when 'list'
#                tnode = labelled "string", text("")
#                lb = listbuffer(tnode)
#                selection.target.put selection.head, lb
#                selection = new Selection(tnode, 0, 0)
#
#    insertCharacter = (txt) ->
#        switch nodeType(selection.target)
#            when 'text'
#                tb = textbuffer(txt)
#                selection.target.put selection.head, tb
#                head = selection.head+txt.length
#                selection.update(head, head)
#            when 'list'
#                tnode = text(txt)
#                lb = listbuffer(tnode)
#                selection.target.put selection.head, lb
#                selection = new Selection(tnode, txt.length, txt.length)
#        return selection
#
#    node_split = (target, index) ->
#        node = text(target.kill(index, target.length).text)
#        {target, stop} = target.getRange()
#        target.put stop, listbuffer(node)
#        return new Selection(node, 0, 0)
#
#    canvas.addEventListener 'mousedown', () ->
#        if over?
#            selection = new Selection over, over.hoverIndex, over.hoverIndex
#            commandSelection = null
#            mode = selectMode
#
#    draw = () ->
#        bc.fillStyle = "#aaa"
#        bc.fillRect(0, 0, canvas.width, canvas.height)
#
#        bc.textBaseline = "middle"
#        model.layout(bc)
#        model.x = 50
#        model.y = 50
#        over = model.mousemotion(mouse.point...)
#        model.draw(bc)
#
#        if commandSelection
#            command.layout(bc)
#            command.x = 50
#            command.y = canvas.height - command.height
#            command.draw(bc)
#            selection.draw(bc)
#        else
#            selection.draw(bc)
#            bc.fillStyle = "white"
#            bc.fillText "-- " + mode.tag + " --", 50, canvas.height - 10
#
#        if currentdoc?
#            bc.fillStyle = "white"
#            path = currentdoc.name
#            path = currentdoc.ent.fullPath if currentdoc.ent?
#            if currentdoc.isModified()
#                path += ' [+]'
#            bc.fillText path, 50, 10
#
#        bc.fillStyle = "white"
#        i = 0
#        for entry in fs.entries
#            bc.fillText entry.fullPath, canvas.width - 64, 50+i*16
#            i += 1
#
#leftSelection = (target) ->
#    return new Selection(target, 0, 0)
#
#rightSelection = (target) ->
#    return new Selection(target, target.length, target.length)
#
#textleft = (selection) ->
#    {target, start, stop} = selection
#    if target.type != 'text' and 0 < start
#        node = target.get start-1
#        return new Selection(node, node.length, node.length) if node.type == 'text'
#    return selection
#
#textright = (selection) ->
#    {target, start, stop} = selection
#    if target.type != 'text' and stop < target.length
#        node = target.get stop
#        return new Selection(node, 0, 0) if node.type == 'text'
#    return selection
#
#travelLeft = (selection) ->
#    {target, head} = selection
#    if target.type == 'text'
#        {start, target} = target.getRange()
#        return travelLeft new Selection(target, start, start)
#    if target.type == 'list'
#        if 0 < head
#            node = target.get head-1
#            if node.type == 'list' or node.type == 'text'
#                return rightSelection node
#            return new Selection(target, head-1, head-1)
#        else if target.parent?
#            {start, target} = target.getRange()
#            return new Selection(target, start, start)
#    return selection
#
#travelRight = (selection) ->
#    {target, head} = selection
#    if target.type == 'text'
#        {stop, target} = target.getRange()
#        return travelRight new Selection(target, stop, stop)
#    if target.type == 'list'
#        if head < target.length
#            node = target.get head
#            if node.type == 'list' or node.type == 'text'
#                return leftSelection node
#            return new Selection(target, head+1, head+1)
#        else if target.parent?
#            {stop, target} = target.getRange()
#            return new Selection(target, stop, stop)
#    return selection
