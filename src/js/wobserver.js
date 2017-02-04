import {WobserverClient} from './wobserver_client';
import {WobserverRender} from './wobserver_render';

class Wobserver {
  constructor(host) {
    this.host = host;
    this.client = new WobserverClient(host);

    this.client.connect( (client) => this.client = client );

    WobserverRender.init(this);
  }

  open_system(){
    this.client.command_promise('system').
    then( WobserverRender.display_system );

    this.refreshInterval = setInterval( () => {
      this.client.command_promise('system').
      then( WobserverRender.display_system )
    }, 1000 );
  }
  close_system(){
    this.refreshInterval = clearInterval(this.refreshInterval);
  }

  open_about(){
    this.client.command_promise('about').
    then( WobserverRender.display_about );
  }
}

export{ Wobserver }