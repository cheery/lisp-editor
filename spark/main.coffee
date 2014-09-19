
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

module.exports = (document) ->
    env.canvas = canvas = document.getElementById('editor')
    env.bc = bc = canvas.getContext '2d'
    window.addEventListener 'resize', resize = () ->
        canvas.width = canvas.offsetWidth
        canvas.height = canvas.offsetHeight
    resize()
    env.clearScreen = () ->
        bc.clearRect 0, 0, canvas.width, canvas.height
    env.draw = () ->
        env.clearScreen()
        bc.fillRect 50, 50, canvas.width - 100, canvas.height - 100
        window.requestAnimationFrame env.draw
    env.draw()

    env.readBlipFile "samples/stdlib.blip"
