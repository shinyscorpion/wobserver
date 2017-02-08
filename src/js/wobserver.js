import {WobserverClient} from './wobserver_client';
import {WobserverRender} from './wobserver_render';

class Wobserver {
  constructor(host) {
    this.host = host;
    this.client = new WobserverClient(host);

    this.update_interval = 250;
    this.refreshTimer = null;

    this.client.connect((n) => WobserverRender.set_node(n), (client) => this.client = client);

    WobserverRender.init(this);
  }

  open_system(){
      this.client.command_promise('system')
      .then(WobserverRender.display_system)
      .then(() => {
        this.refreshTimer = setTimeout(() => this.open_system(), this.update_interval);
      })
      .catch((e) => {})
  }
  close_system(){
    this.refreshTimer = clearInterval(this.refreshTimer);
  }

  open_about(){
    this.client.command_promise('about').
    then( WobserverRender.display_about );
  }
}

export{ Wobserver }