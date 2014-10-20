
CoffeeScript = require('coffee-script')
net = require('net')
fs = require('fs')


# to use the gate:
# map <C-Enter> :w !nc -U gate.sock<CR><CR>
gate_path = "./gate.sock"

if fs.existsSync(gate_path)
    fs.unlinkSync(gate_path)
server = net.createServer (c) ->
    cache = ""
    c.on 'data', (data) ->
        cache += data.toString()
    c.on 'end', () ->
        CoffeeScript.run(cache)
server.listen(gate_path)

GLOBAL.env = env = {}

require './src/node'
require './src/blip'
require './src/teh'

module.exports = (document) ->
    env.canvas = canvas = document.getElementById('editor')
    env.bc = bc = canvas.getContext '2d'
    env.mouse = mouseInput(canvas)
    window.addEventListener 'resize', resize = () ->
        canvas.width = canvas.offsetWidth
        canvas.height = canvas.offsetHeight
    resize()
    window.addEventListener 'mousedown', (args...) -> env.mousedown(args...)
    window.addEventListener 'mouseup',   (args...) -> env.mouseup(args...)
    env.mousedown = () ->
    env.mouseup   = () ->
    env.clearScreen = () ->
        bc.clearRect 0, 0, canvas.width, canvas.height
    env.draw = () ->
        env.clearScreen()
        bc.fillRect 50, 50, canvas.width - 100, canvas.height - 100
        window.requestAnimationFrame env.draw
    env.draw()

    env.readBlipFile "samples/stdlib.blip"

mouseInput = (canvas) ->
    mouse = {x:0, y:0}
    canvas.addEventListener 'mousemove', mousemove = (e) ->
        rect = canvas.getBoundingClientRect()
        mouse.x = (e.clientX - rect.left) / rect.width * canvas.width
        mouse.y = (e.clientY - rect.top) / rect.height * canvas.height
    return mouse
