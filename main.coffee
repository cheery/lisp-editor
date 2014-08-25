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

    cursor = liftRight {index:0, node:root}
    

    frame = null

    canvas.addEventListener 'click', (ev) ->
        ev.preventDefault()
        if (near = frame.nearest(mouse.point...))?
            cursor = {index:near.index, node:near.frame.node}

    selectMode = (code) ->
        if code == "i"
            return insertMode
        if code == "v"
            return visualMode
        if code == "h"
            cursor = stepLeft cursor
        if code == "l"
            cursor = stepRight cursor
        if code == "j"
            cursor = flowLeft cursor
        if code == "k"
            cursor = flowRight cursor
        if code == "w"
            cursor = tabRight cursor
        if code == "e"
            if isText(cursor.node) and cursor.index < cursor.node.length
                cursor = indexBottom cursor.node
            else
                cursor = tabRight cursor
                cursor = indexBottom cursor.node if isText(cursor.node)
        if code == "b"
            if isText(cursor.node) and 0 < cursor.index
                cursor = indexTop cursor.node
            else
                cursor = tabLeft cursor
                cursor = indexTop cursor.node if isText(cursor.node)
        if code == "<" and cursor.node.parent?
            {node, index} = cursor
            lst = node.parent
            index = lst.indexOf node
            if index > 0
                lst.put(index-1, lst.kill(index, index+1), false)
        if code == ">" and cursor.node.parent?
            {node, index} = cursor
            lst = node.parent
            index = lst.indexOf node
            if index < lst.length - 1
                lst.put(index+1, lst.kill(index, index+1), false)
        if code == " " and isText(cursor.node)
            if cursor.index == 0
                cursor = indexBefore cursor.node
            if cursor.index == cursor.node.length
                cursor = indexAfter cursor.node
        return selectMode
    selectMode.tag = "select"

#    selectMode = (keyCode, txt) ->
#        if txt == ':'
#            commandSelection = selection
#            command = list()
#            selection = new Selection(command, 0, 0)
#            mode = commandMode
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

    insertMode = (code) ->
        if code == 27
            return selectMode
#       else if code == ","
#           go to nodeinsert mode
        else if code == " "
            cursor = splitNode cursor
        else if code == 13
            cursor = splitNode splitNode cursor
            cursor.node.put cursor.index, newList([newMark('cr')]), false
            cursor.index += 1
        else if code == "("
            cursor = splitnode splitNode cursor
            cursor.node.put cursor.index, newList([node=newList([])]), false
            cursor.node  = node
            cursor.index = 0
        else if code == ")"
            if isText(cursor.node)
                cursor = indexAfter cursor.node
            cursor = indexAfter cursor.node
        else if code == ";"
            if isText(cursor.node)
                newlabel = cursor.node.text
                cursor = indexBefore cursor.node
                cursor.node.kill cursor.index, cursor.index+1
                cursor.node.relabel newlabel
            else
                cursor.node.relabel null
#        else if code == '"'
#            insertString() go into string insert mode.
        else if code == 8
            cursor = deleteLeft(cursor)
        else if code == 46
            cursor = deleteRight(cursor)
        else if typeof code == 'string'
            if isText(cursor.node)
                cursor.node.put cursor.index, newText(code), false
                cursor.index += 1
            else if isList(cursor.node)
                cursor.node.put cursor.index, newList([node = newText(code)]), false
                cursor.node  = node
                cursor.index = 1
        return insertMode
    insertMode.tag = "insert"

    visualMode = (code) ->
        if code == 27
            return selectMode
#       else if code == ","
#           go to nodeinsert mode
        return mode
    visualMode.tag = "visual"
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
#    visualMode.tag = "visual"

    mode = selectMode
    keyboardEvents canvas, (keyCode, text) ->
        code = if text == "" then keyCode else text
        mode = mode(code)


    draw = () ->
        bc.fillStyle = "#ccc"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        frame = newFrame root, buildStyle defaultStyle, {
            indent: 0
            verticalSpacing: 25
        }
        first = true
        for node in frame.node.list
            frame.newline() unless first
            addFrame(frame, node)
            first = false
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

        bc.fillStyle = 'black'
        bc.fillText " Some commands in the help are missing due to an update.", 0, 30

        bc.fillRect(0, canvas.height-16, canvas.width, 16)
        bc.fillStyle = 'white'
        bc.fillText " -- #{mode.tag} --", 0, canvas.height - 5

        requestAnimationFrame draw
    draw()

deleteUnder = (cursor) ->
    cursor.node.kill cursor.index, cursor.index+1
    return cursor

deleteLeft = (cursor) ->
    {node, index} = cursor = cursor
    if isText(node)
        if index > 0
            cursor = deleteUnder {node, index:index-1}
            if node.length == 0 and node.parent?
                cursor = deleteUnder indexBefore node
        else if node.parent?
            {node, index} = cursor = indexBefore cursor
            child = node.list[index-1]
            if isText(child)
                postfix = node.kill(index, index+1).list[0]
                cursor = indexBottom child
                cursor.node.put(cursor.index, postfix, false)
            else
                cursor = deleteLeft(cursor)
    else if isList(node)
        child = node.list[index-1]
        if index == 0 and node.parent?
            cursor = indexBefore node
            if node.length == 0
                deleteUnder cursor
        else if isList(child)
            cursor = indexBottom child
        else if isText(child)
            cursor = deleteLeft indexBottom child
        else
            cursor = deleteUnder {node, index:index-1}
    return cursor

deleteRight = (cursor) ->
    {node, index} = cursor = cursor
    if isText(node)
        if index < node.length
            cursor = deleteUnder {node, index:index}
            if node.length == 0 and node.parent?
                cursor = deleteUnder indexBefore node
        else if node.parent?
            {node, index} = cursor = indexAfter cursor
            child = node.list[index]
            if isText(child)
                postfix = node.kill(index, index+1).list[0]
                cursor = indexBottom node.list[index-1]
                cursor.node.put(cursor.index, postfix, false)
            else
                cursor = deleteRight(cursor)
    else if isList(node)
        child = node.list[index]
        if index == node.length and node.parent?
            if node.length == 0
                cursor = deleteUnder indexBefore node
            else
                cursor = indexAfter node
        else if isList(child)
            cursor = indexTop child
        else if isText(child)
            cursor = deleteRight indexTop child
        else
            cursor = deleteUnder {node, index:index}
    return cursor

splitNode = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        if index == 0
            return indexBefore node
        if index == node.length
            return indexAfter node
        prefix = newList([node.kill(0, index)])
        ins = indexBefore(node)
        ins.node.put ins.index, prefix, false
        return {node, index:0}
    return cursor

flowLeft = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = liftLeft indexBefore node
    else if isList(node)
        if index > 0
            cursor = {node:node, index:index-1}
        else if node.parent?
            cursor = indexBefore node
    return cursor

flowRight = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = liftRight indexAfter node
    else if isList(node)
        if index < node.length
            cursor = {node:node, index:index+1}
        else if node.parent?
            cursor = indexAfter node
    return cursor

tabLeft = (cursor) ->
    {node, index} = cursor = travelLeft cursor
    if index == 0 and not node.parent?
        return cursor
    if isList(node) and node.length > 0
        return tabLeft(cursor)
    return cursor

tabRight = (cursor) ->
    {node, index} = cursor = travelRight cursor
    if index == node.length and not node.parent?
        return cursor
    if isList(node) and node.length > 0
        return tabRight(cursor)
    return cursor

stepLeft = (cursor) ->
    {node, index} = cursor
    if isText(node) and 0 < index
        cursor = {node, index:index - 1}
    else
        cursor = travelLeft cursor
    return cursor

stepRight = (cursor) ->
    {node, index} = cursor
    if isText(node) and index < node.length
        cursor = {node, index:index + 1}
    else
        cursor = travelRight cursor
    return cursor

travelLeft = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = travelLeft indexBefore node
    else if isList(node)
        if 0 < index
            child = node.list[index-1]
            if isList(child) or isText(child)
                cursor = indexBottom child
            else
                cursor = {node, index:index-1}
        else if node.parent?
            cursor = indexBefore node
    return liftLeft cursor

travelRight = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = travelRight indexAfter node
    else if isList(node)
        if index < node.length
            child = node.list[index]
            if isList(child) or isText(child)
                cursor = indexTop child
            else
                cursor = {node, index:index+1}
        else if node.parent?
            cursor = indexAfter node
    return liftRight cursor

liftLeft = (cursor) ->
    {node, index} = cursor
    if isList(node)
        child = node.list[index-1]
        cursor = indexBottom child if isText(child)
    return cursor

liftRight = (cursor) ->
    {node, index} = cursor
    if isList(node)
        child = node.list[index]
        cursor = indexTop child if isText(child)
    return cursor

indexTop = (node) ->
    return {node:node, index:0}

indexBottom = (node) ->
    return {node:node, index:node.length}

indexBefore = (node) ->
    return {node:node.parent, index:node.parent.indexOf(node)}

indexAfter = (node) ->
    return {node:node.parent, index:node.parent.indexOf(node)+1}



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
#    inString = (selection) ->
#        return selection.target.type == "text" and selection.target.label == "string"
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
#    copybuffer = null
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
