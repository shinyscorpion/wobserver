import {Popup} from './popup.js';

class NodeDialog {
  constructor(wobserver) {
    this.wobserver = wobserver;
  }

  show() {
    this.wobserver.client.command_promise('nodes')
    .then((nodes) => {
      Popup.show(`
      <div id="node_selection">
        <span>Select node:</span>
        <ul id="node_options">
        </ul>
      </div>
      `);

      let node_options = document.getElementById('node_options');

      nodes.forEach((node) => {
        let li = document.createElement('li');

        li.className = (this.wobserver.client.node == node.name) ? 'node selected' : 'node';

        let local_class = node['local?'] ? ' (local)' : '';

        li.innerHTML = `<span>${node.name}${local_class}</span><detail>${node.host}:${node.port}</detail>`

        li.addEventListener('click', () =>{
          this.wobserver.client.set_node(node.name);
          this.hide();
        });

        node_options.appendChild(li);
      });
    });
  }

  hide() {
    Popup.hide();
  }
}

export{ NodeDialog }