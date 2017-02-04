function build_url(host, command) {
  return 'http://' + host + '/api/' + command;
 }
class WobserverApiFallback {
  constructor(host) {
    this.host = host;
  }

  command(command, data = null) {
    console.log('Send fallback command');
  }

  command_promise(command, data = null) {
    return fetch(build_url(this.host, command)).then(res => res.json());
  }
}

export{ WobserverApiFallback }
