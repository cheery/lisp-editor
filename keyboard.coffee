window.keyboardEvents = (canvas, callback) ->
    node = document.createElement("input")
    node.style.position = "absolute"
    node.style.left = "-10000px"
    canvas.parentNode.insertBefore(node, canvas)

    node.addEventListener 'keydown', (ev) ->
        keyCode = ev.keyCode
        ev.preventDefault() if keyCode == 9
        node.value = ""
        keyhandler = () ->
            callback(keyCode, node.value)
        setTimeout keyhandler, 0
    node.focus()

    canvas.addEventListener 'click', () ->
        node.focus()
