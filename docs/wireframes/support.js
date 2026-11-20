/*
 * ワイヤーフレーム（*.dc.html）をブラウザ単体で表示するための最小ランタイム。
 * {{path}} の差し込み、<sc-for>、<sc-if>、onClick / onChange などのイベント、
 * renderVals() と setState() による再描画だけに対応する。
 */
(function () {
  class DCLogic {
    constructor(props) {
      this.props = props || {};
      this.state = {};
    }
    setState(patch) {
      Object.assign(this.state, typeof patch === 'function' ? patch(this.state) : patch);
      if (this.__render) this.__render();
    }
    forceUpdate() {
      if (this.__render) this.__render();
    }
  }
  window.DCLogic = DCLogic;

  const HOLE = /\{\{\s*([^}]+?)\s*\}\}/g;
  const WHOLE = /^\s*\{\{\s*([^}]+?)\s*\}\}\s*$/;

  function lookup(scope, path) {
    path = path.trim();
    if (path === 'true') return true;
    if (path === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(path)) return Number(path);
    return path.split('.').reduce((v, k) => (v == null ? undefined : v[k]), scope);
  }

  function interpolate(text, scope) {
    return text.replace(HOLE, (_, p) => {
      const v = lookup(scope, p);
      return v == null ? '' : String(v);
    });
  }

  function renderNode(node, scope, out) {
    if (node.nodeType === Node.TEXT_NODE) {
      out.appendChild(document.createTextNode(interpolate(node.nodeValue, scope)));
      return;
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return;
    const tag = node.tagName.toLowerCase();

    if (tag === 'sc-for') {
      const list = lookup(scope, (node.getAttribute('list') || '').replace(/[{}]/g, '')) || [];
      const as = node.getAttribute('as') || 'item';
      list.forEach((item, i) => {
        const child = Object.assign(Object.create(scope), { [as]: item, $index: i });
        node.childNodes.forEach((c) => renderNode(c, child, out));
      });
      return;
    }
    if (tag === 'sc-if') {
      if (lookup(scope, (node.getAttribute('value') || '').replace(/[{}]/g, ''))) {
        node.childNodes.forEach((c) => renderNode(c, scope, out));
      }
      return;
    }

    const el = node.namespaceURI === 'http://www.w3.org/2000/svg'
      ? document.createElementNS(node.namespaceURI, node.localName)
      : document.createElement(node.localName);
    for (const attr of Array.from(node.attributes)) {
      const name = attr.name;
      const whole = attr.value.match(WHOLE);
      if (name.startsWith('on') && whole) {
        const fn = lookup(scope, whole[1]);
        if (typeof fn === 'function') el.addEventListener(name.slice(2).toLowerCase(), fn);
        continue;
      }
      if (name.startsWith('hint-')) continue;
      if (whole) {
        const v = lookup(scope, whole[1]);
        if (v == null || v === false) continue;
      }
      el.setAttribute(name, interpolate(attr.value, scope));
    }
    const src = tag === 'template' ? node.content : node;
    src.childNodes.forEach((c) => renderNode(c, scope, el));
    out.appendChild(el);
  }

  function boot() {
    const host = document.querySelector('x-dc');
    if (!host) return;
    const helmet = host.querySelector('helmet');
    if (helmet) {
      Array.from(helmet.children).forEach((c) => document.head.appendChild(c));
      helmet.remove();
    }
    const tpl = document.createElement('template');
    tpl.innerHTML = host.innerHTML;

    let Component = class extends DCLogic { renderVals() { return {}; } };
    const script = document.querySelector('script[data-dc-script]');
    if (script) {
      Component = new Function('DCLogic', script.textContent + '\nreturn Component;')(DCLogic);
    }
    const instance = new Component({});
    const mount = document.createElement('div');
    host.replaceWith(mount);

    instance.__render = () => {
      const keyOf = (c, seen) => {
        const base = [c.tagName, c.type, c.getAttribute('aria-label'), c.getAttribute('placeholder'), c.name].join('|');
        const n = seen[base] = (seen[base] || 0) + 1;
        return base + '#' + n;
      };
      const kept = {};
      const seenA = {};
      Array.from(mount.querySelectorAll('input, select, textarea')).forEach((c) => {
        kept[keyOf(c, seenA)] = c.type === 'checkbox' ? c.checked : c.value;
      });
      const frag = document.createDocumentFragment();
      const scope = instance.renderVals() || {};
      tpl.content.childNodes.forEach((c) => renderNode(c, scope, frag));
      mount.replaceChildren(frag);
      const seenB = {};
      Array.from(mount.querySelectorAll('input, select, textarea')).forEach((c) => {
        const k = keyOf(c, seenB);
        if (!(k in kept)) return;
        if (c.type === 'checkbox') c.checked = kept[k];
        else c.value = kept[k];
      });
    };
    instance.__render();
    if (instance.componentDidMount) instance.componentDidMount();
  }

  const style = document.createElement('style');
  style.textContent = 'x-dc{display:none}';
  document.head.appendChild(style);
  document.addEventListener('DOMContentLoaded', boot);
})();
