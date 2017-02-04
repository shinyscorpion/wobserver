import {WobserverApiFallback} from './wobserver_api_fallback';

class WobserverClient {
  constructor(host) {
    this.host = host;
    this.socket = null;
    this.promises = {}
  }

  connect(fallback_callback) {
    this.socket =  new WebSocket('ws://' + this.host + '/ws');

    this.socket.onerror = (error) => {
      if( this.socket.readyState == 3 ){
        console.log('Socket can not connect, falling back to json api.')
        fallback_callback(new WobserverApiFallback(this.host));
      }
    }

    this.socket.onopen = () => {
      this.command('hello');
    }

    this.socket.onmessage = (msg) => {
      let data = JSON.parse(msg.data);

      console.log(data)

      if( this.promises[data.type] ){
        let promise = this.promises[data.type].pop();
        if( promise ) {
          promise(data.data);
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
}

export{ WobserverClient }
