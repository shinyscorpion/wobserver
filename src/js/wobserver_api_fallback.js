function build_url(host, command, node = "") {
  if( node == "local" ){
    return 'http://' + host + '/api/' + encodeURI(command).replace(/#/g, '%23');
  } else {
    return 'http://' + host + '/api/' + encodeURI(node) + "/" + encodeURI(command).replace(/#/g, '%23');
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
    .then(data => { return {
      data: data,
      timestamp: Date.now() / 1000 | 0,
      type: command,
    } } )
    .catch( _ => {} );
  }

  set_node(node) {
    this.node = node;
  }
}

export{ WobserverApiFallback }
