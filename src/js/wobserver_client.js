class WobserverClient {
  constructor(host) {
    this.host = host;
    this.socket = null;
    this.promises = {}
  }

  connect() {
    this.socket =  new WebSocket(this.host);

    this.socket.onopen = () => {
      this.command('hello');
    }

    this.socket.onmessage = (msg) => {
      let data = JSON.parse(msg.data);

      if( this.promises[data.type] ){
        this.promises[data.type].pop()(data.data);
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
