function build_url(host, command, node = "") {
  if( node == "local" ){
    return 'http://' + host + '/api/' + command;
  } else {
    return 'http://' + host + '/api/' + node + "/" + command;
  }
}

class WobserverApiFallback {
  constructor(host, node = "local") {
    this.host = host;
    this.node = node;
  }

  command(command, data = null) {
    console.log('Send fallback command');
  }

  command_promise(command, data = null) {
    return fetch(build_url(this.host, command, this.node))
    .then(res => res.json())
    .catch((e) =>{} );
  }

  set_node(node) {
    this.node = node;
  }
}

export{ WobserverApiFallback }
