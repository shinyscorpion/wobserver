import {WobserverApiFallback} from './wobserver_api_fallback';

class WobserverClient {
  constructor(host) {
    this.host = host;
    this.socket = null;
    this.node = 'local';
    this.promises = {}
  }

  connect(node_change, fallback_callback, connected_callback) {
    this.node_change = node_change;

    this.socket =  new WebSocket('ws://' + this.host + '/ws');

    this.socket.onerror = (error) => {
      if( this.socket.readyState == 3 ){
        console.log('Socket can not connect, falling back to json api.')
        fallback_callback(new WobserverApiFallback(this.host, this.node));
        connected_callback();
      }
    }

    this.socket.onopen = () => {
      connected_callback();

      this.command('hello');
      setInterval(_ => this.command('ping') );
    }

    this.socket.onmessage = (msg) => {
      let data = JSON.parse(msg.data);

      if( data.type == 'ehlo' ) {
        this.node = data.data.name;
        this.node_change(this.node);
      } else if( data.type == 'setup_proxy' && data.data.node) {
        this.node = data.data.node;
        this.node_change(this.node);
      } else {
        if( this.promises[data.type] ){
          let promise = this.promises[data.type].pop();
          if( promise ) {
            promise(data);
          }
        }
      }
    }
  }

  command(command, data = null) {
    let payload = JSON.stringify({
      command: command,
      data: data
    })

    this.socket.send(payload);
  }

  command_promise(command, data = null) {
    return new Promise((resolve) => {
      if( this.promises[command] ){
        this.promises[command].push(resolve);
      } else {
        this.promises[command] = [resolve];
      }

      this.command(command, data);
    });
  }

  set_node(node) {
    if( this.node != node ) {
      this.command('setup_proxy', node)
    }
  }
}

export{ WobserverClient }
