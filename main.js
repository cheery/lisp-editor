// Generated by CoffeeScript 1.6.3
(function() {
  var Carriage, ListNode, TextNode, cr, list, padding, text,
    __slice = [].slice;

  window.addEventListener('load', function() {
    var bc, canvas, draw, drawBox, model;
    canvas = autoResize(document.getElementById('editor'));
    bc = canvas.getContext('2d');
    model = list(text("define"), list(text("factorial"), text("n")), cr(), list(text("if"), list(text("="), text("n"), text("0")), text("1"), cr(), list(text("*"), text("n"), list(text("factorial"), list(text("-"), text("n"), text("1"))))));
    window.model = model;
    draw = function() {
      bc.fillStyle = "#aaa";
      bc.fillRect(0, 0, canvas.width, canvas.height);
      bc.textBaseline = "middle";
      model.layout(bc);
      model.x = 50;
      model.y = 50;
      model.draw(bc);
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

  TextNode = (function() {
    function TextNode(text) {
      this.text = text;
      this.type = 'text';
    }

    TextNode.prototype.layout = function(bc) {
      bc.font = "16px sans-serif";
      this.x = 0;
      this.y = 0;
      this.width = bc.measureText(this.text).width;
      return this.height = 16;
    };

    TextNode.prototype.draw = function(bc) {
      bc.font = "16px sans-serif";
      bc.fillStyle = "black";
      return bc.fillText(this.text, this.x, this.y + this.height / 2, this.width);
    };

    return TextNode;

  })();

  padding = 8;

  ListNode = (function() {
    function ListNode(list) {
      this.list = list;
      this.type = 'list';
    }

    ListNode.prototype.layout = function(bc) {
      var item, offset, row, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      this.x = 0;
      this.y = 0;
      this.width = 0;
      this.height = 0;
      this.rows = [];
      this.rows.push(row = {
        offset: padding,
        offsets: [padding],
        frames: [],
        height: 16
      });
      offset = padding;
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        item.layout(bc);
        if (item.type === 'cr') {
          this.rows.push(row = {
            offset: row.offset + row.height + padding,
            offsets: [padding],
            frames: [],
            height: 16
          });
          this.width = Math.max(offset, this.width);
          this.height = Math.max(row.offset + row.height + 2 * padding, this.height);
          offset = padding;
        } else {
          item.x = offset;
          item.y = row.offset;
          offset += padding + item.width;
          row.offsets.push(offset);
          row.frames.push(item);
          row.height = Math.max(row.height, item.height);
        }
      }
      this.width = Math.max(offset, this.width);
      this.height = Math.max(row.offset + row.height + padding, this.height);
      _ref1 = this.rows;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        row = _ref1[_j];
        _ref2 = row.frames;
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          item = _ref2[_k];
          item.y += row.height / 2 - item.height / 2;
        }
      }
      if (this.rows.length > 1) {
        this.width += padding;
      }
      if (this.rows.length > 1) {
        return this.height += padding;
      }
    };

    ListNode.prototype.draw = function(bc) {
      var item, _i, _len, _ref;
      bc.fillStyle = "white";
      bc.fillRect(this.x, this.y, this.width, this.height);
      bc.strokeRect(this.x, this.y, this.width, this.height);
      bc.save();
      bc.translate(this.x, this.y);
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        item.draw(bc);
      }
      return bc.restore();
    };

    return ListNode;

  })();

  Carriage = (function() {
    function Carriage(list) {
      this.list = list;
      this.type = 'cr';
    }

    Carriage.prototype.layout = function(bc) {
      this.x = 0;
      this.y = 0;
      this.height = 0;
      return this.width = 0;
    };

    Carriage.prototype.draw = function(bc) {};

    return Carriage;

  })();

  cr = function() {
    return new Carriage();
  };

  text = function(text) {
    return new TextNode(text);
  };

  list = function() {
    var data;
    data = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new ListNode(data);
  };

}).call(this);
