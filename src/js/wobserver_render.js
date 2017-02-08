import {Popup} from './interface/popup.js';
import {NodeDialog} from './interface/node_dialog.js';

// Helpers
function time_formatter(time) {
  let seconds = Math.floor(time / 1000);

  let days    = Math.floor(seconds / 86400); seconds -= days * 86400;
  let hours   = Math.floor(seconds / 3600);  seconds -= hours * 3600;
  let minutes = Math.floor(seconds / 60);    seconds -= minutes * 60;

  if( hours   < 10 ) {hours   = '0' + hours;}
  if( minutes < 10 ) {minutes = '0' + minutes;}
  if( seconds < 10 ) {seconds = '0' + seconds;}

  if( days > 0 ){
    return days + 'days, ' + hours + ':' + minutes + ':' + seconds;
  }

  return hours + ':' + minutes + ':' + seconds;
}
function byte_formatter(usage) {
  let unit = ['B', 'kB', 'MB', 'GB'];
  let unit_counter = 0;

  while( unit_counter < unit.length && usage / 1024 > 8 ){
    usage /= 1024;
    unit_counter++;
  }

  return Math.round(usage) + ' ' + unit[unit_counter];
}

function memory_formatter(memory) {
  return Object.keys(memory).reduce( (formatted_memory, type) => {
    formatted_memory[type] = byte_formatter(memory[type]);
    return formatted_memory;
  }, {});
}

function select_menu(nav, menu_item, item) {
  nav.childNodes.forEach( (child) => child.className = '' );
  menu_item.className = 'selected';

  if( nav.lastItem && nav.lastItem.on_close ){
    nav.lastItem.on_close();
  }

  item.on_open();

  nav.lastItem = item;
  if( history.pushState ) {
    history.pushState(null, null, '#' + item.title);
  } else {
    location.hash = '#' + item.title;
  }
}

function create_menu(items){
  let menu = document.getElementById('menu');
  let nav = document.createElement('nav');

  nav.lastItem = null;

  let first = false;

  items.map((item) => {
    let menu_item = document.createElement('a');
    let menu_text = document.createTextNode(item.title);

    //menu_item.setAttribute('href', '#');
    menu_item.appendChild(menu_text);
    menu_item.addEventListener('click', () => {
      select_menu(nav, menu_item, item);
    });

    nav.appendChild(menu_item);

    item.menu_item = menu_item;

    return item;
  });


  menu.appendChild(nav);

  setTimeout(() => {
    let select = items.find((item) => '#' + item.title == window.location.hash);

    if( !select ){
      select = items[0];
    }

    select_menu(nav, select.menu_item, select);
  }, 100);
}

function create_footer(wobserver) {
  let footer = document.getElementById('footer');

  let switch_button = document.createElement('span');
  switch_button.className = 'button';
  switch_button.style.marginRight = "1em";
  switch_button.innerHTML = 'Switch Node';

  let node_selection = new NodeDialog(wobserver);

  switch_button.addEventListener('click', () => node_selection.show() );

  footer.appendChild(switch_button);

  let node = document.createElement('span');

  node.innerHTML = `Connected to: <em id="connected_node">local</em>.`

  footer.appendChild(node);
}

const WobserverRender = {
  init: (wobserver) => {
    window.onload = () => {
      let wobserver_root = document.getElementById('wobserver');

      wobserver_root.innerHTML =
        `<div id="menu"></div>
        <div id="content"></div>
        <div id="footer"></div>`;

      create_footer(wobserver);

      create_menu([
        {
          title: 'System',
          on_open: () => wobserver.open_system(),
          on_close: () => wobserver.close_system()
        },
        {
          title: 'About',
          on_open: () => wobserver.open_about()
        }
      ]);
    }
  },
  set_node: (node) => {
    document.getElementById('connected_node').innerHTML = node;
  },
  display_system: (system) => {
    let content = document.getElementById('content');

    let architecture =
      `<table class="inline">
        <caption>System and Architecture</caption>
        <tr><th>System Version</th><td>${system.architecture.elixir_version}</td></tr>
        <tr><th>Erlang/OTP Version</th><td>${system.architecture.otp_release}</td></tr>
        <tr><th>ERTS Version</th><td>${system.architecture.erts_version}</td></tr>
        <tr><th>Compiled for</th><td>${system.architecture.system_architecture}</td></tr>
        <tr><th>Emulated Wordsize</th><td>${system.architecture.wordsize_external}</td></tr>
        <tr><th>Process Wordsize</th><td>${system.architecture.wordsize_internal}</td></tr>
        <tr><th>SMP Support</th><td>${system.architecture.smp_support}</td></tr>
        <tr><th>Thread Support</th><td>${system.architecture.threads}</td></tr>
        <tr><th>Async thread pool size</th><td>${system.architecture.thread_pool_size}</td></tr>
      </table>`;

    let cpu =
      `<table class="inline">
        <caption>CPU's and Threads</caption>
        <tr><th>Logical CPU's</th><td>${system.cpu.logical_processors}</td></tr>
        <tr><th>Online Logical CPU's</th><td>${system.cpu.logical_processors_online}</td></tr>
        <tr><th>Available Logical CPU's</th><td>${system.cpu.logical_processors_available}</td></tr>
        <tr><th>Schedulers</th><td>${system.cpu.schedulers}</td></tr>
        <tr><th>Online schedulers</th><td>${system.cpu.schedulers_online}</td></tr>
        <tr><th>Available schedulers</th><td>${system.cpu.schedulers_available}</td></tr>
      </table>`;

    let memory_formatted = memory_formatter(system.memory);

    let memory =
      `<table class="inline">
        <caption>Memory Usage</caption>
        <tr><th>Total</th><td>${memory_formatted.total}</td></tr>
        <tr><th>Processes</th><td>${memory_formatted.process}</td></tr>
        <tr><th>Atoms</th><td>${memory_formatted.atom}</td></tr>
        <tr><th>Binaries</th><td>${memory_formatted.binary}</td></tr>
        <tr><th>Code</th><td>${memory_formatted.code}</td></tr>
        <tr><th>ETS</th><td>${memory_formatted.ets}</td></tr>
      </table>`;

    let statistics =
      `<table class="inline">
        <caption>Statistics</caption>
        <tr><th>Up time</th><td>${time_formatter(system.statistics.uptime)}</td></tr>
        <tr><th>Max Processes</th><td>${system.statistics.process_max}</td></tr>
        <tr><th>Processes</th><td>${system.statistics.process_total}</td></tr>
        <tr><th>Run Queue</th><td>${system.statistics.process_running}</td></tr>
        <tr><th>IO Input</th><td>${byte_formatter(system.statistics.input)}</td></tr>
        <tr><th>IO Output</th><td>${byte_formatter(system.statistics.output)}</td></tr>
      </table>`;

    content.innerHTML = architecture + cpu + memory + statistics;
  },
  display_about: (about) => {
    let content = document.getElementById('content');

    let urls = about.links.map( (url) => {
      return `<tr><th>${url.name}</th><td><a href="${url.url}">${url.url}</a></td></tr>`
    }).join('');

    content.innerHTML = `
      <h1 style="margin-bottom:0;">${about.name}</h1>
      <span style="font-weight:bold;font-size:80%;font-style:italic;">Version: ${about.version}</span>
      <p>${about.description}</p>
      <h2>Info</h2>
      <table style="text-align: left;">
        <tr><th>Licence</th><td><a href="${about.license.url}">${about.license.name}</a></td></tr>
        ${urls}
      </table>
    `;
  }
};

export{ WobserverRender }
