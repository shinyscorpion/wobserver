function build_url(host, command, node = "") {
  if( node == "local" ){
    return location.protocol + "//" + host + '/api/' + encodeURI(command).replace(/#/g, '%23');
  } else {
    return location.protocol + "//" + host + '/api/' + encodeURI(node) + "/" + encodeURI(command).replace(/#/g, '%23');
  }
}

class WobserverApiFallback {
  constructor(host, node = "local") {
    this.host = host;
    this.node = node;
    this.connected = true;
  }

  command(command, data = null) {
    fetch(build_url(this.host, command, this.node))
  }

  command_promise(command, data = null) {
    return fetch(build_url(this.host, command, this.node))
    .then(res => res.json())
    .then(data => { return {
      data: data,
      timestamp: Date.now() / 1000 | 0,
      type: command,
    } } )
    .then(e => {
      if( !this.connected ){
        this.connected = true;
        this.on_reconnect()
      }

      return e;
    })
    .catch(_ => {
      this.connected = false;
      this.on_disconnect();
    });
  }

  set_node(node) {
    this.node = node;
  }
}

export{ WobserverApiFallback }
