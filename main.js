// Generated by CoffeeScript 1.6.3
(function() {
  var Selection, leftSelection, rightSelection, textleft, textright, travelLeft, travelRight;

  window.addEventListener('load', function() {
    var bc, canvas, copybuffer, delLeft, delRight, draw, drawBox, insertBox, insertCharacter, insertCr, insertMode, insertSpace, mode, model, mouse, node_split, outOfBox, over, selectMode, selection, stepLeft, stepRight, visualMode;
    canvas = autoResize(document.getElementById('editor'));
    bc = canvas.getContext('2d');
    model = list(text("define"), list(text("factorial"), text("n")), cr(), list(text("if"), list(text("="), text("n"), text("0")), cr(), text("1"), cr(), list(text("*"), text("n"), list(text("factorial"), list(text("-"), text("n"), text("1"))))));
    mouse = mouseInput(canvas);
    window.model = model;
    over = null;
    mode = null;
    selection = textright(leftSelection(model));
    insertMode = function(keyCode, txt) {
      if (keyCode === 27) {
        return mode = selectMode;
      } else if (keyCode === 13) {
        return insertCr();
      } else if (txt === " ") {
        return insertSpace();
      } else if (txt === "(") {
        return insertBox();
      } else if (txt === ")") {
        return outOfBox();
      } else if (txt.length > 0) {
        return insertCharacter(txt);
      } else if (keyCode === 8) {
        return selection = delLeft(selection);
      } else if (keyCode === 46) {
        return selection = delRight(selection);
      } else {
        return console.log(keyCode);
      }
    };
    insertMode.tag = "insert";
    delLeft = function(selection) {
      var before, head, index, node, start, stop, target, textnode, _ref, _ref1, _ref2;
      target = selection.target, head = selection.head;
      if (target.type === 'text') {
        if (head > 0) {
          target.kill(head - 1, head);
          if (target.length === 0) {
            _ref = target.getRange(), target = _ref.target, start = _ref.start, stop = _ref.stop;
            target.kill(start, stop);
            return new Selection(target, start, start);
          }
          return new Selection(target, head - 1, head - 1);
        } else {
          _ref1 = target.getRange(), node = _ref1.target, start = _ref1.start, stop = _ref1.stop;
          if (start > 0) {
            before = node.get(start - 1);
            if (before.type === 'text') {
              textnode = text(before.text + target.text);
              index = before.length;
              node.kill(start - 1, stop);
              node.put(start, listbuffer(textnode));
              return new Selection(textnode, index, index);
            }
          }
          return delLeft(new Selection(node, 0, 0));
        }
      }
      if (target.type === 'list') {
        if (head > 0) {
          before = target.get(head - 1);
          if (before.type === 'list') {
            return new Selection(before, before.length, before.length);
          }
          if (before.type === 'text') {
            return delLeft(new Selection(before, before.length, before.length));
          }
          target.kill(head - 1, head);
          return new Selection(target, head - 1, head - 1);
        } else if (target.parent != null) {
          _ref2 = target.getRange(), node = _ref2.target, start = _ref2.start, stop = _ref2.stop;
          if (target.length === 0) {
            node.kill(start, stop);
          }
          return new Selection(node, start, start);
        }
      }
      return selection;
    };
    delRight = function(selection) {
      var ahead, head, index, node, start, stop, target, textnode, _ref, _ref1, _ref2;
      target = selection.target, head = selection.head;
      if (target.type === 'text') {
        if (head < target.length) {
          target.kill(head, head + 1);
          if (target.length === 0) {
            _ref = target.getRange(), target = _ref.target, start = _ref.start, stop = _ref.stop;
            target.kill(start, stop);
            return new Selection(target, start, start);
          }
          return new Selection(target, head, head);
        } else {
          _ref1 = target.getRange(), node = _ref1.target, start = _ref1.start, stop = _ref1.stop;
          if (stop < node.length) {
            ahead = node.get(stop);
            if (ahead.type === 'text') {
              textnode = text(target.text + ahead.text);
              index = target.length;
              node.kill(start, stop + 1);
              node.put(start, listbuffer(textnode));
              return new Selection(textnode, index, index);
            }
          }
          return delRight(new Selection(node, stop, stop));
        }
      }
      if (target.type === 'list') {
        if (head < target.length) {
          ahead = target.get(head);
          if (ahead.type === 'list') {
            return new Selection(ahead, 0, 0);
          }
          if (ahead.type === 'text') {
            return delRight(new Selection(ahead, 0, 0));
          }
          target.kill(head, head + 1);
          return new Selection(target, head, head);
        } else if (target.parent != null) {
          _ref2 = target.getRange(), node = _ref2.target, start = _ref2.start, stop = _ref2.stop;
          if (target.length === 0) {
            node.kill(start, stop);
            return new Selection(node, start, start);
          }
          return new Selection(node, stop, stop);
        }
      }
      return selection;
    };
    copybuffer = null;
    visualMode = function(keyCode, text) {
      var head, inclusive, start, stop, tail, target, _ref, _ref1, _ref2;
      if (keyCode === 27) {
        mode = selectMode;
        return selection.update(selection.head, selection.head, false);
      } else if (text === 'h') {
        target = selection.target, head = selection.head, tail = selection.tail, inclusive = selection.inclusive;
        if (head > 0) {
          return selection.update(head - 1, tail, inclusive);
        } else {
          _ref = target.getRange(), target = _ref.target, start = _ref.start;
          return selection = new Selection(target, start, start, true);
        }
      } else if (text === 'l') {
        target = selection.target, head = selection.head, tail = selection.tail, inclusive = selection.inclusive;
        if (head < target.length - 1) {
          return selection.update(head + 1, tail, inclusive);
        } else {
          _ref1 = target.getRange(), target = _ref1.target, start = _ref1.start;
          return selection = new Selection(target, start, start, true);
        }
      } else if (text === 'v' && (selection.target.parent != null)) {
        _ref2 = selection.target.getRange(), target = _ref2.target, start = _ref2.start;
        return selection = new Selection(target, start, start, true);
      } else if (text === 'd') {
        target = selection.target, start = selection.start, stop = selection.stop;
        copybuffer = target.kill(start, stop);
        selection.update(start, start, false);
        return mode = selectMode;
      } else if (text === 'y') {
        target = selection.target, start = selection.start, stop = selection.stop;
        copybuffer = target.yank(start, stop);
        selection.update(start, start, false);
        return mode = selectMode;
      }
    };
    visualMode.tag = "visual";
    selectMode = function(keyCode, txt) {
      var buf, head, start, stop, target, _ref, _ref1, _ref2, _ref3;
      if (txt === ' ' && selection.target.type === 'text') {
        if (selection.head === selection.target.length) {
          _ref = selection.target.getRange(), target = _ref.target, stop = _ref.stop;
          selection = new Selection(target, stop, stop);
        } else if (selection.head === 0) {
          _ref1 = selection.target.getRange(), target = _ref1.target, start = _ref1.start;
          selection = new Selection(target, start, start);
        }
      }
      if (txt === 'i') {
        mode = insertMode;
      }
      if (txt === 'l') {
        selection = stepRight(selection);
      }
      if (txt === 'w') {
        selection = textright(travelRight(selection));
      }
      if (txt === 'e') {
        if (selection.target.type !== 'text' || selection.head === selection.target.length) {
          selection = textright(travelRight(selection));
        }
        if (selection.target.type === 'text') {
          selection.update(selection.target.length, selection.target.length);
        }
      }
      if (txt === 'h') {
        selection = stepLeft(selection);
      }
      if (txt === 'b') {
        if (selection.target.type !== 'text' || selection.head === 0) {
          selection = textleft(travelLeft(selection));
        }
        if (selection.target.type === 'text') {
          selection.update(0, 0);
        }
      }
      if (txt === 'v') {
        mode = visualMode;
        selection.update(selection.head, selection.tail, true);
      }
      if (txt === 'P' && (copybuffer != null)) {
        target = selection.target, head = selection.head;
        switch (nodeType(target)) {
          case "text":
            if (copybuffer.type === 'textbuffer') {
              target.put(head, copybuffer);
            }
            if (copybuffer.type === 'listbuffer') {
              _ref2 = target.getRange(), target = _ref2.target, start = _ref2.start;
              target.put(start, copybuffer);
            }
            break;
          case "list":
            if (copybuffer.type === 'textbuffer') {
              buf = listbuffer(text(copybuffer.text));
              target.put(head, buf);
            }
            if (copybuffer.type === 'listbuffer') {
              target.put(head, copybuffer);
            }
        }
      }
      if (txt === 'p' && (copybuffer != null)) {
        target = selection.target, head = selection.head;
        switch (nodeType(target)) {
          case "text":
            if (copybuffer.type === 'textbuffer') {
              target.put(head, copybuffer);
            }
            if (copybuffer.type === 'listbuffer') {
              _ref3 = target.getRange(), target = _ref3.target, stop = _ref3.stop;
              return target.put(stop, copybuffer);
            }
            break;
          case "list":
            if (copybuffer.type === 'textbuffer') {
              target.put(head, listbuffer(text(copybuffer.text)));
            }
            if (copybuffer.type === 'listbuffer') {
              return target.put(head, copybuffer);
            }
        }
      }
    };
    selectMode.tag = "select";
    stepLeft = function(selection) {
      if (0 < selection.head && selection.target.type === 'text') {
        selection = new Selection(selection.target, selection.head - 1, selection.head - 1);
      } else {
        selection = textleft(travelLeft(selection));
      }
      return selection;
    };
    stepRight = function(selection) {
      if (selection.head < selection.target.length && selection.target.type === 'text') {
        selection = new Selection(selection.target, selection.head + 1, selection.head + 1);
      } else {
        selection = textright(travelRight(selection));
      }
      return selection;
    };
    insertCr = function() {
      var head, start, stop, target, _ref, _ref1, _ref2, _ref3;
      if (selection.target.type === 'text') {
        if ((0 < (_ref = selection.head) && _ref < selection.target.length)) {
          node_split(selection.target, selection.head);
          _ref1 = selection.target.getRange(), target = _ref1.target, stop = _ref1.stop;
          selection = new Selection(target, stop, stop);
        } else if (selection.head === selection.target.length) {
          _ref2 = selection.target.getRange(), target = _ref2.target, stop = _ref2.stop;
          selection = new Selection(target, stop, stop);
        } else if (selection.head === 0) {
          _ref3 = selection.target.getRange(), target = _ref3.target, start = _ref3.start;
          selection = new Selection(target, start, start);
        }
      }
      selection.target.put(selection.head, listbuffer(cr()));
      head = selection.head + 1;
      selection.update(head, head);
      return selection;
    };
    insertSpace = function() {
      var head, start, stop, target, _ref, _ref1;
      if (selection.target.type === 'text') {
        head = selection.head, target = selection.target;
        if (head === target.length) {
          _ref = target.getRange(), target = _ref.target, stop = _ref.stop;
          selection = new Selection(target, stop, stop);
        } else if (head === 0) {
          _ref1 = target.getRange(), target = _ref1.target, start = _ref1.start;
          selection = new Selection(target, start, start);
        } else {
          selection = node_split(target, head);
        }
      }
      return selection;
    };
    insertBox = function() {
      var head, obj, start, stop, target, _ref, _ref1, _ref2;
      if (selection.target.type === 'text') {
        head = selection.head, target = selection.target;
        if (head === target.length) {
          _ref = target.getRange(), target = _ref.target, stop = _ref.stop;
          selection = new Selection(target, stop, stop);
        } else if (head === 0) {
          _ref1 = target.getRange(), target = _ref1.target, start = _ref1.start;
          selection = new Selection(target, start, start);
        } else {
          selection = node_split(target, head);
          _ref2 = target.getRange(), target = _ref2.target, stop = _ref2.stop;
          selection = new Selection(target, stop, stop);
        }
      }
      obj = list();
      selection.target.put(selection.head, listbuffer(obj));
      selection.target = obj;
      selection.update(0, 0);
      return selection;
    };
    outOfBox = function() {
      var range, target;
      if (selection.target.type === 'text') {
        target = selection.target.getRange().target;
      } else {
        target = selection.target;
      }
      if ((range = target.getRange()) != null) {
        selection = new Selection(range.target, range.stop, range.stop);
      }
      return selection;
    };
    insertCharacter = function(txt) {
      var head, lb, tb, tnode;
      switch (nodeType(selection.target)) {
        case 'text':
          tb = textbuffer(txt);
          selection.target.put(selection.head, tb);
          head = selection.head + txt.length;
          selection.update(head, head);
          break;
        case 'list':
          tnode = text(txt);
          lb = listbuffer(tnode);
          selection.target.put(selection.head, lb);
          selection = new Selection(tnode, txt.length, txt.length);
      }
      return selection;
    };
    node_split = function(target, index) {
      var node, stop, _ref;
      node = text(target.kill(index, target.length).text);
      _ref = target.getRange(), target = _ref.target, stop = _ref.stop;
      target.put(stop, listbuffer(node));
      return new Selection(node, 0, 0);
    };
    mode = selectMode;
    keyboardEvents(canvas, function(keyCode, text) {
      return mode(keyCode, text);
    });
    canvas.addEventListener('mousedown', function() {
      if (over != null) {
        return selection = new Selection(over, over.hoverIndex, over.hoverIndex);
      }
    });
    draw = function() {
      bc.fillStyle = "#aaa";
      bc.fillRect(0, 0, canvas.width, canvas.height);
      bc.textBaseline = "middle";
      model.layout(bc);
      model.x = 50;
      model.y = 50;
      over = model.mousemotion.apply(model, mouse.point);
      model.draw(bc);
      selection.draw(bc);
      bc.fillStyle = "white";
      bc.fillText("-- " + mode.tag + " --", 50, canvas.height - 10);
      return requestAnimationFrame(draw);
    };
    drawBox = function(x, y, w, h) {
      bc.beginPath();
      bc.rect(x, y, w, h);
      bc.fill();
      return bc.stroke();
    };
    return draw();
  });

  Selection = (function() {
    function Selection(target, head, tail, inclusive) {
      this.target = target;
      this.head = head;
      this.tail = tail;
      this.inclusive = inclusive != null ? inclusive : false;
      this.update(this.head, this.tail, this.inclusive);
    }

    Selection.prototype.update = function(head, tail, inclusive) {
      this.head = head;
      this.tail = tail;
      this.inclusive = inclusive != null ? inclusive : false;
      if (this.inclusive) {
        this.head = Math.max(0, Math.min(this.head, this.target.length - 1));
        this.tail = Math.max(0, Math.min(this.tail, this.target.length - 1));
      } else {
        this.head = Math.max(0, Math.min(this.head, this.target.length));
        this.tail = Math.max(0, Math.min(this.tail, this.target.length));
      }
      this.start = Math.min(this.head, this.tail);
      return this.stop = Math.max(this.head + this.inclusive, this.tail + this.inclusive);
    };

    Selection.prototype.draw = function(bc) {
      return this.target.drawSelection(bc, this.start, this.stop);
    };

    return Selection;

  })();

  leftSelection = function(target) {
    return new Selection(target, 0, 0);
  };

  rightSelection = function(target) {
    return new Selection(target, target.length, target.length);
  };

  textleft = function(selection) {
    var node, start, stop, target;
    target = selection.target, start = selection.start, stop = selection.stop;
    if (target.type !== 'text' && 0 < start) {
      node = target.get(start - 1);
      if (node.type === 'text') {
        return new Selection(node, node.length, node.length);
      }
    }
    return selection;
  };

  textright = function(selection) {
    var node, start, stop, target;
    target = selection.target, start = selection.start, stop = selection.stop;
    if (target.type !== 'text' && stop < target.length) {
      node = target.get(stop);
      if (node.type === 'text') {
        return new Selection(node, 0, 0);
      }
    }
    return selection;
  };

  travelLeft = function(selection) {
    var head, node, start, target, _ref, _ref1;
    target = selection.target, head = selection.head;
    if (target.type === 'text') {
      _ref = target.getRange(), start = _ref.start, target = _ref.target;
      return travelLeft(new Selection(target, start, start));
    }
    if (target.type === 'list') {
      if (0 < head) {
        node = target.get(head - 1);
        if (node.type === 'list' || node.type === 'text') {
          return rightSelection(node);
        }
        return new Selection(target, head - 1, head - 1);
      } else if (target.parent != null) {
        _ref1 = target.getRange(), start = _ref1.start, target = _ref1.target;
        return new Selection(target, start, start);
      }
    }
    return selection;
  };

  travelRight = function(selection) {
    var head, node, stop, target, _ref, _ref1;
    target = selection.target, head = selection.head;
    if (target.type === 'text') {
      _ref = target.getRange(), stop = _ref.stop, target = _ref.target;
      return travelRight(new Selection(target, stop, stop));
    }
    if (target.type === 'list') {
      if (head < target.length) {
        node = target.get(head);
        if (node.type === 'list' || node.type === 'text') {
          return leftSelection(node);
        }
        return new Selection(target, head + 1, head + 1);
      } else if (target.parent != null) {
        _ref1 = target.getRange(), stop = _ref1.stop, target = _ref1.target;
        return new Selection(target, stop, stop);
      }
    }
    return selection;
  };

}).call(this);
