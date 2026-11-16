'use strict';

var assert = require('assert');
var History = require('./history.js');

var clock = 0;

function harness(over) {
  var box = { state: { a: 0 } };
  var opts = {
    getState: function () { return box.state; },
    setState: function (s) { box.state = s; },
    now: function () { return clock; }
  };
  if (over) for (var k in over) opts[k] = over[k];
  box.history = History.create(opts);
  return box;
}

function labels(h) {
  return h.list().map(function (e) { return e.label; });
}

// initial entry
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  assert.strictEqual(h.size, 1);
  assert.strictEqual(h.index, 0);
  assert.strictEqual(h.canUndo(), false);
  assert.strictEqual(h.canRedo(), false);
  assert.strictEqual(h.list()[0].label, 'Início');
  assert.strictEqual(h.list()[0].current, true);
})();

// commit adds
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  assert.strictEqual(h.commit('Um'), true);
  assert.strictEqual(h.size, 2);
  assert.strictEqual(h.index, 1);
  assert.strictEqual(h.canUndo(), true);
  assert.strictEqual(h.list()[1].label, 'Um');
})();

// identical commit ignored
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  clock = 20;
  assert.strictEqual(h.commit('De novo'), false);
  assert.strictEqual(h.size, 2);
  assert.deepStrictEqual(labels(h), ['Início', 'Um']);
})();

// undo / redo
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  assert.strictEqual(h.undo(), true);
  assert.deepStrictEqual(box.state, { a: 0 });
  assert.strictEqual(h.index, 0);
  assert.strictEqual(h.undo(), false);
  assert.strictEqual(h.redo(), true);
  assert.deepStrictEqual(box.state, { a: 1 });
  assert.strictEqual(h.index, 1);
  assert.strictEqual(h.redo(), false);
})();

// commit after undo drops the redo branch
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  clock = 20;
  box.state = { a: 2 };
  h.commit('Dois');
  h.undo();
  clock = 30;
  box.state = { a: 3 };
  assert.strictEqual(h.commit('Três'), true);
  assert.strictEqual(h.size, 3);
  assert.strictEqual(h.index, 2);
  assert.strictEqual(h.canRedo(), false);
  assert.deepStrictEqual(labels(h), ['Início', 'Um', 'Três']);
})();

// coalescing with the same key inside coalesceMs
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 100;
  box.state = { v: 1 };
  h.commit('Arrastar', 'tamanho');
  clock = 300;
  box.state = { v: 2 };
  assert.strictEqual(h.commit('Arrastar', 'tamanho'), true);
  assert.strictEqual(h.size, 2);
  assert.strictEqual(h.index, 1);
  h.undo();
  assert.deepStrictEqual(box.state, { a: 0 });
  h.redo();
  assert.deepStrictEqual(box.state, { v: 2 });
})();

// coalescing beyond coalesceMs adds a new entry
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 100;
  box.state = { v: 1 };
  h.commit('Arrastar', 'tamanho');
  clock = 300;
  box.state = { v: 2 };
  h.commit('Arrastar', 'tamanho');
  clock = 1000;
  box.state = { v: 3 };
  assert.strictEqual(h.commit('Arrastar', 'tamanho'), true);
  assert.strictEqual(h.size, 3);
  assert.strictEqual(h.index, 2);
})();

// limit drops the oldest and keeps the index valid
(function () {
  clock = 0;
  var box = harness({ limit: 3 });
  var h = box.history;
  for (var i = 1; i <= 5; i++) {
    clock = i * 1000;
    box.state = { a: i };
    h.commit('Passo ' + i);
  }
  assert.strictEqual(h.size, 3);
  assert.strictEqual(h.index, 2);
  assert.deepStrictEqual(labels(h), ['Passo 3', 'Passo 4', 'Passo 5']);
  assert.strictEqual(h.list()[2].current, true);
  assert.strictEqual(h.canRedo(), false);
  assert.strictEqual(h.undo(), true);
  assert.deepStrictEqual(box.state, { a: 4 });
  assert.strictEqual(h.index, 1);
})();

// jump
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  clock = 20;
  box.state = { a: 2 };
  h.commit('Dois');
  assert.strictEqual(h.index, 2);
  assert.strictEqual(h.jump(0), true);
  assert.deepStrictEqual(box.state, { a: 0 });
  assert.strictEqual(h.index, 0);
  assert.strictEqual(h.jump(0), false);
  assert.strictEqual(h.jump(99), true);
  assert.strictEqual(h.index, 2);
  assert.deepStrictEqual(box.state, { a: 2 });
  assert.strictEqual(h.jump(-1), true);
  assert.strictEqual(h.index, 0);
})();

// list() flags the current entry
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  clock = 20;
  box.state = { a: 2 };
  h.commit('Dois');
  h.undo();
  var items = h.list();
  assert.strictEqual(items.length, 3);
  assert.deepStrictEqual(items.map(function (e) { return e.index; }), [0, 1, 2]);
  assert.deepStrictEqual(items.map(function (e) { return e.current; }), [false, true, false]);
  assert.strictEqual(items[1].label, 'Um');
  assert.strictEqual(typeof items[1].t, 'number');
})();

// onChange fires and unsubscribe works
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  var calls = 0;
  var received = null;
  var off = h.onChange(function (x) { calls++; received = x; });
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  assert.strictEqual(calls, 1);
  assert.strictEqual(received, h);
  h.undo();
  assert.strictEqual(calls, 2);
  h.redo();
  assert.strictEqual(calls, 3);
  h.jump(0);
  assert.strictEqual(calls, 4);
  assert.strictEqual(h.commit('Igual'), false);
  assert.strictEqual(calls, 4);
  box.state = { a: 9 };
  h.commit('Nove');
  assert.strictEqual(calls, 5);
  off();
  box.state = { a: 10 };
  h.commit('Dez');
  assert.strictEqual(calls, 5);
})();

// commit inside setState is ignored
(function () {
  clock = 0;
  var state = { a: 0 };
  var inner = [];
  var h;
  h = History.create({
    getState: function () { return state; },
    setState: function (s) { state = s; inner.push(h.commit('De dentro')); },
    now: function () { return clock; }
  });
  clock = 10;
  state = { a: 1 };
  h.commit('Um');
  var sizeBefore = h.size;
  assert.strictEqual(h.undo(), true);
  assert.strictEqual(inner.length, 1);
  assert.strictEqual(inner[0], false);
  assert.strictEqual(h.size, sizeBefore);
  assert.strictEqual(h.index, 0);
  assert.strictEqual(h.redo(), true);
  assert.strictEqual(inner.length, 2);
  assert.strictEqual(inner[1], false);
  assert.strictEqual(h.size, sizeBefore);
  assert.deepStrictEqual(state, { a: 1 });
})();

// clear()
(function () {
  clock = 0;
  var box = harness();
  var h = box.history;
  clock = 10;
  box.state = { a: 1 };
  h.commit('Um');
  clock = 20;
  box.state = { a: 2 };
  h.commit('Dois');
  h.clear();
  assert.strictEqual(h.size, 1);
  assert.strictEqual(h.index, 0);
  assert.strictEqual(h.canUndo(), false);
  assert.strictEqual(h.canRedo(), false);
  assert.deepStrictEqual(labels(h), ['Início']);
  assert.deepStrictEqual(box.state, { a: 2 });
  assert.strictEqual(h.commit('Igual'), false);
})();

console.log('ok');
