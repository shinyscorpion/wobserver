import {Wobserver} from './wobserver';

let host = window.location.host + window.location.pathname;
if( host.endsWith("/") ) {
  host = host.substr(0, host.length - 1);
}

let wobserver = new Wobserver(host);
