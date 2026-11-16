(function (root, f) {
  if (typeof module === 'object' && module.exports) module.exports = f();
  else root.MS_Path = f();
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  var DUP_EPS = 1e-9;

  function sub(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; }
  function cross(a, b) {
    return [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0]
    ];
  }
  function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
  function len3(a) { return Math.sqrt(dot(a, a)); }
  function normalize(a) {
    var l = len3(a);
    if (l < 1e-12) return [0, 0, 0];
    return [a[0] / l, a[1] / l, a[2] / l];
  }
  function copy(p) { return [p[0], p[1], p[2]]; }
  function clamp01(v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

  function build(points) {
    var pts = [];
    var i;
    var input = points || [];
    for (i = 0; i < input.length; i++) {
      var p = input[i];
      if (!p) continue;
      var q = copy(p);
      if (pts.length) {
        var d = sub(q, pts[pts.length - 1]);
        if (len3(d) < DUP_EPS) continue;
      }
      pts.push(q);
    }

    var cum = [];
    var total = 0;
    for (i = 0; i < pts.length; i++) {
      if (i === 0) {
        cum[0] = 0;
      } else {
        total += len3(sub(pts[i], pts[i - 1]));
        cum[i] = total;
      }
    }
    return { pts: pts, cum: cum, length: total };
  }

  function segmentAtS(path, s) {
    var cum = path.cum;
    var lo = 0;
    var hi = path.pts.length - 1;
    while (lo < hi - 1) {
      var mid = (lo + hi) >> 1;
      if (cum[mid] <= s) lo = mid;
      else hi = mid;
    }
    return lo;
  }

  function posAtS(path, s) {
    var pts = path.pts;
    if (pts.length === 0) return [0, 0, 0];
    if (pts.length === 1) return copy(pts[0]);
    if (path.length <= 0) return copy(pts[0]);
    if (s <= 0) return copy(pts[0]);
    if (s >= path.length) return copy(pts[pts.length - 1]);

    var i = segmentAtS(path, s);
    var a = pts[i];
    var b = pts[i + 1];
    var segLen = path.cum[i + 1] - path.cum[i];
    var t = segLen > 0 ? (s - path.cum[i]) / segLen : 0;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t
    ];
  }

  function dirAtS(path, s) {
    var pts = path.pts;
    if (pts.length < 2) return [1, 0, 0];
    if (path.length <= 0) return [1, 0, 0];
    var ss = s < 0 ? 0 : (s > path.length ? path.length : s);
    var i = segmentAtS(path, ss);
    var d = normalize(sub(pts[i + 1], pts[i]));
    if (len3(d) < 1e-12) return [1, 0, 0];
    return d;
  }

  function at(path, u, eps) {
    if (!(eps > 0)) eps = 0.01;

    var uu = clamp01(u);
    if (!path || !path.pts || path.length <= 0) {
      var p0 = (path && path.pts && path.pts.length) ? path.pts[0] : [0, 0, 0];
      return { pos: copy(p0), tangent: [1, 0, 0], s: 0 };
    }

    var total = path.length;
    var s = uu * total;
    var pos = posAtS(path, s);

    var a = posAtS(path, clamp01(uu - eps) * total);
    var b = posAtS(path, clamp01(uu + eps) * total);
    var tangent = normalize(sub(b, a));
    if (len3(tangent) < 1e-12) tangent = dirAtS(path, s);
    if (len3(tangent) < 1e-12) tangent = [1, 0, 0];

    return { pos: pos, tangent: tangent, s: s };
  }

  function resample(points, n) {
    var count = Math.floor(n || 0);
    if (!(count >= 2)) count = 2;
    var path = build(points);
    var out = [];
    var i;

    if (path.length <= 0) {
      var p = path.pts.length ? path.pts[0] : [0, 0, 0];
      for (i = 0; i < count; i++) out.push(copy(p));
      return out;
    }

    for (i = 0; i < count; i++) {
      if (i === 0) out.push(copy(path.pts[0]));
      else if (i === count - 1) out.push(copy(path.pts[path.pts.length - 1]));
      else out.push(posAtS(path, path.length * i / (count - 1)));
    }
    return out;
  }

  function smooth(points, passes) {
    var rounds = (passes === undefined || passes === null) ? 1 : Math.floor(passes);
    if (!(rounds > 0)) rounds = 0;
    var cur = [];
    var i;
    var input = points || [];
    for (i = 0; i < input.length; i++) cur.push(copy(input[i]));
    if (cur.length < 3) return cur;

    for (var k = 0; k < rounds; k++) {
      var next = [];
      for (i = 0; i < cur.length; i++) next.push(copy(cur[i]));
      for (i = 1; i < cur.length - 1; i++) {
        next[i][0] = (cur[i - 1][0] + cur[i][0] + cur[i + 1][0]) / 3;
        next[i][1] = (cur[i - 1][1] + cur[i][1] + cur[i + 1][1]) / 3;
        next[i][2] = (cur[i - 1][2] + cur[i][2] + cur[i + 1][2]) / 3;
      }
      cur = next;
    }
    return cur;
  }

  function quatAlignX(tangent, up) {
    var x = normalize(copy(tangent || [1, 0, 0]));
    if (len3(x) < 1e-12) x = [1, 0, 0];

    var u = normalize(copy(up || [0, 1, 0]));
    if (len3(u) < 1e-12) u = [0, 1, 0];

    var z = cross(x, u);
    if (len3(z) < 1e-9) {
      var helper = Math.abs(x[0]) < 0.9 ? [1, 0, 0] : [0, 0, 1];
      z = cross(x, helper);
    }
    z = normalize(z);
    var y = normalize(cross(z, x));

    var m00 = x[0], m10 = x[1], m20 = x[2];
    var m01 = y[0], m11 = y[1], m21 = y[2];
    var m02 = z[0], m12 = z[1], m22 = z[2];

    var tr = m00 + m11 + m22;
    var qx, qy, qz, qw, S;

    if (tr > 0) {
      S = Math.sqrt(tr + 1) * 2;
      qw = 0.25 * S;
      qx = (m21 - m12) / S;
      qy = (m02 - m20) / S;
      qz = (m10 - m01) / S;
    } else if (m00 > m11 && m00 > m22) {
      S = Math.sqrt(1 + m00 - m11 - m22) * 2;
      qw = (m21 - m12) / S;
      qx = 0.25 * S;
      qy = (m01 + m10) / S;
      qz = (m02 + m20) / S;
    } else if (m11 > m22) {
      S = Math.sqrt(1 + m11 - m00 - m22) * 2;
      qw = (m02 - m20) / S;
      qx = (m01 + m10) / S;
      qy = 0.25 * S;
      qz = (m12 + m21) / S;
    } else {
      S = Math.sqrt(1 + m22 - m00 - m11) * 2;
      qw = (m10 - m01) / S;
      qx = (m02 + m20) / S;
      qy = (m12 + m21) / S;
      qz = 0.25 * S;
    }

    var ql = Math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw) || 1;
    return [qx / ql, qy / ql, qz / ql, qw / ql];
  }

  function eulerFromQuat(q) {
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var x2 = x + x, y2 = y + y, z2 = z + z;
    var xx = x * x2, xy = x * y2, xz = x * z2;
    var yy = y * y2, yz = y * z2, zz = z * z2;
    var wx = w * x2, wy = w * y2, wz = w * z2;

    var m11 = 1 - (yy + zz);
    var m12 = xy - wz;
    var m13 = xz + wy;
    var m22 = 1 - (xx + zz);
    var m23 = yz - wx;
    var m32 = yz + wx;
    var m33 = 1 - (xx + yy);

    var c = m13 < -1 ? -1 : (m13 > 1 ? 1 : m13);
    var ey = Math.asin(c);
    var ex, ez;
    if (Math.abs(m13) < 0.9999999) {
      ex = Math.atan2(-m23, m33);
      ez = Math.atan2(-m12, m11);
    } else {
      ex = Math.atan2(m32, m22);
      ez = 0;
    }

    var rad2deg = 180 / Math.PI;
    return [ex * rad2deg, ey * rad2deg, ez * rad2deg];
  }

  function trail(path, u, opts) {
    opts = opts || {};
    var count = (opts.count === undefined) ? 6 : Math.floor(opts.count);
    if (!(count >= 1)) count = 1;
    var lagU = (opts.lagU === undefined) ? 0.04 : opts.lagU;
    var fade = opts.fade || 'linear';

    var out = [];
    for (var i = 0; i < count; i++) {
      var ui = clamp01(u - i * lagU);
      var r = at(path, ui);
      out.push({
        i: i,
        u: ui,
        pos: r.pos,
        tangent: r.tangent,
        alpha: fade === 'none' ? 1 : 1 - i / count
      });
    }
    return out;
  }

  return {
    build: build,
    at: at,
    resample: resample,
    smooth: smooth,
    quatAlignX: quatAlignX,
    eulerFromQuat: eulerFromQuat,
    trail: trail
  };
});
