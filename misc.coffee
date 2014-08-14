window.AudioContext ?= window.webkitAudioContext

window.mouseInput = (canvas) ->
    mouse = {point:[0, 0]}
    document.addEventListener 'mousemove', mousemove = (e) ->
        rect = canvas.getBoundingClientRect()
        mouse.point[0] = (e.clientX - rect.left) / rect.width * canvas.width
        mouse.point[1] = (e.clientY - rect.top) / rect.height * canvas.height
    return mouse

window.autoResize = (canvas) ->
    window.addEventListener 'resize', resize = () ->
        canvas.width = canvas.clientWidth
        canvas.height = canvas.clientHeight
    resize()
    return canvas

window.every = (secs, func) ->
    setInterval func, secs*1000

window.gameLoop = (fps, func) ->
    setInterval (() -> func(1/fps)), 1000/fps
