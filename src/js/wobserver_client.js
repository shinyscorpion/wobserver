import {WobserverApiFallback} from './wobserver_api_fallback';

class WobserverClient {
  constructor(host) {
    this.host = host;
    this.socket = null;
    this.node = 'local';
    this.promises = {}
    this.state = 0;
  }

  connect(node_change, fallback_callback, connected_callback) {
    this.node_change = node_change;

    this.socket = new WebSocket('ws://' + this.host + '/ws');

    this.socket.onerror = (error) => {
      if( this.socket.readyState == 3 ){
        if( this.state == 0 ){
          console.log('Socket can not connect, falling back to json api.')
          fallback_callback(new WobserverApiFallback(this.host, this.node));
          connected_callback();
        }
      }
    }

    this.socket.onopen = () => {
      this.state = 1;

      connected_callback();

      this.command('hello');
      setInterval(_ => this.command('ping') );
    }

    this.add_handlers();
  }

  disconnected() {
    if( this.state == 1 ){
      this.state = -1;

      this.reconnect();
    }

    if( this.on_disconnect ){
      this.on_disconnect();
    }
  }

  reconnect() {
    let new_socket = new WebSocket('ws://' + this.host + '/ws');

    new_socket.onerror = (error) => {
      if( this.socket.readyState == 3 ){
        console.log('Reconnect failed, trying again in 5 seconds.')
        setTimeout(_ => this.reconnect(), 5000);
      }
    }

    new_socket.onopen = () => {
      this.socket = new_socket;
      this.state = 1;

      this.add_handlers();

      this.command('hello');

      if( this.on_reconnect ){
        this.on_reconnect();
      }
    }
  }

  add_handlers() {
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
    if( this.socket.readyState == 3 ){
      this.disconnected();

      return;
    }

    let payload = JSON.stringify({
      command: command,
      data: data
    })

    this.socket.send(payload);
  }

  command_promise(command, data = null) {
    if( this.socket.readyState == 3 ){
      this.disconnected();

      return new Promise((s) => {});
    }

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
