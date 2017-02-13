import {WobserverClient} from './wobserver_client';
import {WobserverRender} from './wobserver_render';

class Wobserver {
  constructor(host) {
    this.host = host;
    this.update_interval = 1000;
    this.refreshTimer = null;

    WobserverRender.init(this);

    this.client = new WobserverClient(host);
    this.client.connect(n => WobserverRender.set_node(n),
      client => this.client = client, () => WobserverRender.load_menu(this));

    window.show_process = process => WobserverRender.show_process(process, this);
    window.show_table = table => WobserverRender.show_table(table, this);
  }

  display(command, renderer) {
    this.client.command_promise(command)
    .then(e => renderer(e))
  }

  open(command, refresh, renderer) {
    clearInterval(this.refreshTimer);
    this.display(command, renderer);

    if( refresh > 0 ) {
      this.refreshTimer = setInterval( () => this.display(command, renderer), refresh * this.update_interval);
    }
  }

  close(command, refresh) {

  }
}

export{ Wobserver }

