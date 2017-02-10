import {WobserverClient} from './wobserver_client';
import {WobserverRender} from './wobserver_render';

class Wobserver {
  constructor(host) {
    this.host = host;
    this.update_interval = 250;
    this.refreshTimer = null;

    WobserverRender.init(this);

    this.client = new WobserverClient(host);
    this.client.connect(n => WobserverRender.set_node(n),
      client => this.client = client);

    window.show_process = process => WobserverRender.show_process(process, this);
    window.show_table = table => WobserverRender.show_table(table, this);
  }

  open_system(){
    this.client.command_promise('system')
    .then(e => WobserverRender.display_system(e.data))
    .then(() => {
      this.refreshTimer = setTimeout(() => this.open_system(), this.update_interval);
    })
  }
  close_system(){
    this.refreshTimer = clearTimeout(this.refreshTimer);
  }

  open_applications() {
    this.client.command_promise('application')
    .then(e => WobserverRender.display_applications(e.data, this));
  }

  open_processes(){
      this.client.command_promise('process')
      .then(e => WobserverRender.display_processes(e.data))
      .then(() => {
        this.refreshTimer = setTimeout(() => this.open_processes(), 4 * this.update_interval);
      })
  }
  close_processes(){
    this.refreshTimer = clearTimeout(this.refreshTimer);
  }

  open_load_charts(){
    this.client.command_promise('system')
    .then(e => WobserverRender.display_load_charts(e))
    .then(() => {
      this.refreshTimer = setTimeout(() => this.open_load_charts(), this.update_interval / 4);
    })
  }
  close_load_charts(){
    this.refreshTimer = clearTimeout(this.refreshTimer);
  }

  open_allocators(){
    this.client.command_promise('allocators')
    .then(e => WobserverRender.display_allocators(e))
    .then(() => {
      this.refreshTimer = setTimeout(() => this.open_allocators(), this.update_interval / 4);
    })
  }
  close_allocators(){
    this.refreshTimer = clearTimeout(this.refreshTimer);
  }

  open_ports(){
      this.client.command_promise('ports')
      .then(e => WobserverRender.display_ports(e.data))
      .then(() => {
        this.refreshTimer = setTimeout(() => this.open_ports(), 8 * this.update_interval);
      })
  }
  close_ports(){
    this.refreshTimer = clearTimeout(this.refreshTimer);
  }

  open_table(){
      this.client.command_promise('table')
      .then(e => WobserverRender.display_table(e.data))
      .then(() => {
        this.refreshTimer = setTimeout(() => this.open_table(), 8 * this.update_interval);
      })
  }
  close_table(){
    this.refreshTimer = clearTimeout(this.refreshTimer);
  }

  open_about(){
    this.client.command_promise('about').
    then( e => WobserverRender.display_about(e.data) );
  }
}

export{ Wobserver }

