import {WobserverClient} from './wobserver_client';

class Wobserver {
  constructor(host) {
    this.host = host;
    this.client = new WobserverClient('ws://' + host + '/ws');

    this.client.connect();
  }

  system_memory() {
    return this.client.command_promise('memory')
  }
}

export{ Wobserver }