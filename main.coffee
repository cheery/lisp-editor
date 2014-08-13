window.addEventListener 'load', () ->
    canvas = autoResize document.getElementById('editor')
    bc = canvas.getContext '2d'

    do draw = () ->
        bc.fillStyle = "#aaa"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        bc.fillStyle = "black"
        bc.fillRect(50, 50, 150, 10)


        requestAnimationFrame draw
