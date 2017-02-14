import {Popup} from './interface/popup.js';
import {NodeDialog} from './interface/node_dialog.js';
import {ProcessDetail} from './interface/process_detail.js';
import {TableDetail} from './interface/table_detail.js';
import {ApplicationGraph} from './interface/application_graph';
import {WobserverChart} from './interface/chart';

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

function select_menu(ol, menu_item, item) {
  ol.querySelectorAll('a').forEach( (child) => child.className = '' );
  // nav.childNodes.forEach( (child) => child.className = '' );
  menu_item.className = 'selected';

  if( ol.lastItem && ol.lastItem.on_close ){
    ol.lastItem.on_close();
  }

  item.on_open();

  ol.lastItem = item;
  if( history.pushState ) {
    history.pushState(null, null, '#' + item.title.replace(' ', ''));
  } else {
    location.hash = '#' + item.title.replace(' ', '');
  }
}

function create_menu(wobserver, additional = []){
  let items = [
      {
        title: 'System',
        icon: 'fa-heartbeat',
        on_open: () => wobserver.open('system', 1, WobserverRender.display_system),
        on_close: () => wobserver.close('system', 1)
      },
      {
        title: 'Load Charts',
        icon: 'fa-area-chart',
        on_open: () => wobserver.open('system', 0.25, WobserverRender.display_load_charts),
        on_close: () => wobserver.close('system', 0.25)
      },
      {
        title: 'Memory Allocators',
        icon: 'fa-microchip',
        on_open: () => wobserver.open('allocators', 0.25, WobserverRender.display_allocators),
        on_close: () => wobserver.close('allocators', 0.25)
      },
      {
        title: 'Applications',
        icon: 'fa-desktop',
        on_open: () => wobserver.open('application', 0, e => WobserverRender.display_applications(e, wobserver)),
      },
      {
        title: 'Processes',
        icon: 'fa-list-alt',
        on_open: () => wobserver.open('process', 4, WobserverRender.display_processes),
        on_close: () => wobserver.close('process', 4)
      },
      {
        title: 'Ports',
        icon: 'fa-usb',
        on_open: () => wobserver.open('ports', 8, WobserverRender.display_ports),
        on_close: () => wobserver.close('ports', 8)
      },
      {
        title: 'Table Viewer',
        icon: 'fa-table',
        on_open: () => wobserver.open('table', 0, WobserverRender.display_table),
        on_close: () => wobserver.close('table', 0)
      }
  ];

  items = items.concat(additional);

  items.push(
  {
    title: 'About',
    icon: 'fa-info',
    on_open: () => wobserver.open('about', 0, WobserverRender.display_about),
  });

  let menu = document.getElementById('menu');
  let ol = menu.querySelector('ol');
  let header = document.createElement('header');
    menu.appendChild(header);
    header.innerHTML = '<i class="elixir-icon"></i> Wobserver';

  if( ol ){
    while (ol.hasChildNodes()) {
        ol.removeChild(ol.lastChild);
    }
  } else {
    ol = document.createElement('ol');
    menu.appendChild(ol);
  }

  ol.lastItem = null;

  let first = false;

  items.map((item) => {
    let menu_item = document.createElement('li');
    let menu_link = document.createElement('a');
    menu_item.appendChild(menu_link);

    let icon = item.icon ? item.icon : 'fa-home';
    menu_link.innerHTML = `<i class="menuIcon fa fa-fw ${icon}"></i><span>${item.title}</span>`;

    menu_link.addEventListener('click', () => {
      select_menu(ol, menu_link, item);
    });

    ol.appendChild(menu_item);

    item.menu_item = menu_link;

    return item;
  });

  setTimeout(() => {
    let select = items.find(item => '#' + item.title.replace(' ', '') == window.location.hash);

    if( !select ){
      select = items[0];
    }

    select_menu(ol, select.menu_item, select);
  }, 100);

  if( !menu.querySelector('.menu-footer') ){
      let footer = document.createElement('div');
      footer.className = 'menu-footer';

      let switch_button = document.createElement('span');
      switch_button.className = 'button-primary';
      switch_button.style.marginRight = "1em";
      switch_button.innerHTML = 'Switch Node';

      let node_selection = new NodeDialog(wobserver);

      switch_button.addEventListener('click', () => node_selection.show() );

      footer.appendChild(switch_button);
      menu.appendChild(footer);
  }
}

function create_footer(wobserver) {
  let footer = document.getElementById('footer');

  let switch_button = document.createElement('span');
  switch_button.className = 'button-primary';
  switch_button.style.marginRight = "1em";
  switch_button.innerHTML = 'Switch Node';

  let node_selection = new NodeDialog(wobserver);

  switch_button.addEventListener('click', () => node_selection.show() );

  footer.appendChild(switch_button);

  let node = document.createElement('span');

  node.innerHTML = `Connected to: <em id="connected_node">local</em>.`

  footer.appendChild(node);
}

function show_application_graph(app_name, description, wobserver) {
  wobserver.client.command_promise('application/' + app_name)
  .then(e => {
    let application = e.data;

    if( app_name != description ) {
      document.getElementById('application_app_description').innerHTML = description;
    } else {
      document.getElementById('application_app_description').innerHTML = '';
    }

    ApplicationGraph.show(application, 'application_chart');

    document.querySelectorAll('.process-node').forEach( node => {
      let node_name = node.getElementsByClassName('node-name')[0].innerText;
      node.addEventListener('click', _ => {
        new ProcessDetail(node_name, wobserver).show();
      });
    });
  });
}

let menu_state = 0;

const WobserverRender = {
  init: (wobserver) => {
    window.onload = () => {
      let wobserver_root = document.getElementById('wobserver');

      wobserver_root.innerHTML =
        `<nav id="menu"></nav>
        <div id="content"></div>
        <div id="footer"></div>`;

      create_footer(wobserver);

      if( menu_state == 1 ){
        WobserverRender.load_menu(wobserver);
      }

      menu_state = 2;
    }
  },
  load_menu: (wobserver) => {
    if( menu_state == 0 ){
      menu_state = 1;
      return;
    }

    wobserver.client.command_promise('custom')
    .then(e => {
      create_menu(wobserver,
        e.data
        .filter(custom => !e.api_only)
        .map(custom => {
          return {
            title: custom.title,
            on_open: () => wobserver.open(custom.command, custom.refresh, WobserverRender.show_custom),
            on_close: () => wobserver.close(custom.command, custom.refresh)
          }
        })
      );
    })
    .catch(_ => create_menu(wobserver));
  },
  set_node: (node) => {
    let label = document.getElementById('connected_node');

    if( label ) {
      label.innerHTML = node;
    } else {
      setTimeout(() => WobserverRender.set_node(node), 100);
    }
  },
  display_system: e => {
    let system = e.data;
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

    //let scheduler_average = (100*system.scheduler.reduce((sum, e) => sum + e, 0) / (system.scheduler.length || 1));
    //let scheduler_average = system.scheduler.map(e=>Math.floor(e*100)+'%').join(',');
    let scheduler_average = system.scheduler.map(e=>'<span class="load">' + Math.floor(e*100)+'</span>%').join(' ');

    let cpu =
      `<table class="inline">
        <caption>CPU's and Threads</caption>
        <tr><th>Logical CPU's</th><td>${system.cpu.logical_processors}</td></tr>
        <tr><th>Online Logical CPU's</th><td>${system.cpu.logical_processors_online}</td></tr>
        <tr><th>Available Logical CPU's</th><td>${system.cpu.logical_processors_available}</td></tr>
        <tr><th>Schedulers</th><td>${system.cpu.schedulers}</td></tr>
        <tr><th>Online schedulers</th><td>${system.cpu.schedulers_online}</td></tr>
        <tr><th>Available schedulers</th><td>${system.cpu.schedulers_available}</td></tr>
        <tr><th>Average sch. Load</th><td>${scheduler_average}</td></tr>
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
  display_applications: (e, wobserver) => {
    let applications = e.data;
    applications.sort(function(a,b){return a.name.localeCompare(b.name);});
    let content = document.getElementById('content');

    let app_list = `<div id="applications_header">
      <label for="applications_app_list">Application:</label>
      <select id="applications_app_list"></select>
      <p id="application_app_description"></p>
    </div>`

    let app_tree = `<div class="chart" id="application_chart"></div>`;

    content.innerHTML = app_list + app_tree;

    let list = document.getElementById('applications_app_list');
    let application_descriptions = {};

    applications.forEach((app) =>{
      let li = document.createElement('option');

      li.value = app.name;
      li.innerHTML = `${app.name} (${app.version})`;
      application_descriptions[app.name] = app.description;

      list.appendChild(li);
    });

    list.addEventListener('change', element => {
      show_application_graph(list.value, application_descriptions[list.value], wobserver)
    });

    show_application_graph(applications[0].name, applications[0].description, wobserver);
  },
  display_processes: e => {
    let processes = e.data;
    let content = document.getElementById('content');
    let table = content.querySelector('table');
    let sorted = -1;
    let reverse = false;

    if( table ) {
      table.querySelectorAll('th').forEach( (e, i) => {
      if(e.className.includes('sorttable_sorted_reverse')){
        sorted = i;
        reverse = true;
      }else if(e.className.includes('sorttable_sorted')){
        sorted = i;
      }})
    }

    let formatted_processes = processes.map( process => {
      return `<tr>
        <td><a href="javascript:window.show_process('${process.pid}')">${process.pid}</a></td>
        <td>${process.init}</td>
        <td>${process.reductions}</td>
        <td>${process.memory}</td>
        <td>${process.message_queue_length}</td>
        <td>${process.current}</td>
      </tr>`
    }).join('');

    content.innerHTML = `
      <table class="process_table" style="text-align: left;">
        <thead><tr>
          <th>Pid</th>
          <th>Name or Initial Function</th>
          <th>Reds</th>
          <th>Memory</th>
          <th>MsgQ</th>
          <th>Current Function</th>
        </tr></thead>
        ${formatted_processes}
      </table>
    `;

    table = content.querySelector('table');
    sorttable.makeSortable(table);

    if( sorted >= 0 ){
      let th = table.getElementsByTagName('th')[sorted];
      sorttable.innerSortFunction.apply(th, []);
      if( reverse ) {
        sorttable.innerSortFunction.apply(th, []);
      }
    }
  },
  display_ports: e => {
    let data = e.data;
    let content = document.getElementById('content');
    let table = content.querySelector('table');
    let sorted = -1;
    let reverse = false;

    if( table ) {
      table.querySelectorAll('th').forEach( (e, i) => {
      if(e.className.includes('sorttable_sorted_reverse')){
        sorted = i;
        reverse = true;
      }else if(e.className.includes('sorttable_sorted')){
        sorted = i;
      }})
    }

    let formatted_ports = data.map( port => {
      let links = port.links.map(link => `<a href="javascript:window.show_process('${link}')">${link}</a>`).join('');
      return `<tr>
        <td>${port.id}</td>
        <td>${port.name}</td>
        <td><a href="javascript:window.show_process('${port.connected}')">${port.connected}</a></td>
        <td>${port.input}</td>
        <td>${port.output}</td>
        <td>${links}</td>
      </tr>`
    }).join('');

    content.innerHTML = `
      <table class="process_table" style="text-align: left;">
        <thead><tr>
          <th>ID</th>
          <th>Name</th>
          <th>Owner</th>
          <th>Input</th>
          <th>Output</th>
          <th>Links</th>
        </tr></thead>
        ${formatted_ports}
      </table>
    `;

    table = content.querySelector('table');
    sorttable.makeSortable(table);

    if( sorted >= 0 ){
      let th = table.getElementsByTagName('th')[sorted];
      sorttable.innerSortFunction.apply(th, []);
      if( reverse ) {
        sorttable.innerSortFunction.apply(th, []);
      }
    }
  },
  display_load_charts: e => {
    let system = e.data;
    let content = document.getElementById('content');
    let scheduler_chart = null;
    let mem_chart = null;
    let io_chart = null;

    if( document.getElementById('memory_chart') ){
      scheduler_chart = document.getElementById('scheduler_chart').chart;
      mem_chart = document.getElementById('memory_chart').chart;
      io_chart = document.getElementById('io_chart').chart;
    } else {
      content.innerHTML = `<div id="scheduler_chart" style="width:100%;"></div><div id="memory_chart"></div><div id="io_chart"></div>`;

      let r_set = [1, 0, 0, 1, 0, 1, 1, 0];
      let g_set = [0, 1, 0, 1, 1, 0, 1, 0];
      let b_set = [0, 0, 1, 0, 1, 1, 1, 0];
      let schedulers_setup = system.scheduler.map( (_,i) => {
        return {
          label: 'S' + (i+1),
          r: r_set[i % 8] == 1 ? 255 : 0,
          g: g_set[i % 8] == 1 ? 255 : 0,
          b: b_set[i % 8] == 1 ? 255 : 0,
        };
      });

      scheduler_chart = new WobserverChart('scheduler_chart', schedulers_setup, '%');

      mem_chart = new WobserverChart('memory_chart', [
        {
          label: 'Total',
          r: 255,
          g: 0,
          b: 0
        },
        {
          label: 'Process',
          r: 0,
          g: 255,
          b: 0
        },
        {
          label: 'Atom',
          r: 0,
          g: 0,
          b: 255
        },
        {
          label: 'Binary',
          r: 255,
          g: 255,
          b: 0
        },
        {
          label: 'Code',
          r: 0,
          g: 255,
          b: 255
        },
        {
          label: 'Ets',
          r: 255,
          g: 0,
          b: 255
        }
      ], 'MB');

      io_chart = new WobserverChart('io_chart', [
        {
          label: 'Input',
          r: 255,
          g: 0,
          b: 0
        },
        {
          label: 'Output',
          r: 0,
          g: 255,
          b: 0
        }
      ], 'MB');
    }

    let data = system.scheduler.map( v => Math.floor(10000 * v) / 100);
    data.timestamp = e.timestamp;

    scheduler_chart.update(data);


    data = [
      system.memory.total,
      system.memory.process,
      system.memory.atom,
      system.memory.binary,
      system.memory.code,
      system.memory.ets,
    ].map( v => Math.floor(v / 1048576))
    data.timestamp = e.timestamp;

    mem_chart.update(data);

    data = [
      system.statistics.input,
      system.statistics.output,
    ].map( v => Math.floor(v / 1048576))
    data.timestamp = e.timestamp;

    io_chart.update(data);
  },
  display_allocators: e => {
    let allocators = e.data;
    let content = document.getElementById('content');

    let size_chart = null;
    let util_chart = null;

    allocators.unshift(allocators.reduce((a, v) =>{
      a.carrier += v.carrier;
      a.block += v.block;

      return a;
    }, {type: 'Total', carrier: 0, block: 0}));

    if( document.getElementById('size_chart') ){
      size_chart = document.getElementById('size_chart').chart;
      util_chart = document.getElementById('util_chart').chart;
    } else {
      content.innerHTML = `<div id="size_chart" style="width:100%;height: 30%;"></div><div id="util_chart" style="width:100%;height: 30%;"></div><div id="alloc_table"></div>`;

      let r_set = [1, 0, 0, 1, 0, 1, 1, 0];
      let g_set = [0, 1, 0, 1, 1, 0, 1, 0];
      let b_set = [0, 0, 1, 0, 1, 1, 1, 0];
      let schedulers_setup = allocators.map( (data, i) => {
        return {
          label: data.type,
          r: r_set[i % 8] == 1 ? 255 : 0,
          g: g_set[i % 8] == 1 ? 255 : 0,
          b: b_set[i % 8] == 1 ? 255 : 0,
        };
      });

      size_chart = new WobserverChart('size_chart', schedulers_setup, '%');
      util_chart = new WobserverChart('util_chart', schedulers_setup, 'MB');
    }

    let data = allocators.map( v => Math.floor(v.block * 100 / v.carrier))
    data.timestamp = e.timestamp;

    size_chart.update(data);

    data = allocators.map( v => Math.floor(v.carrier / 1048576))
    data.timestamp = e.timestamp;
    util_chart.update(data);

    let alloc_table = document.getElementById('alloc_table');

    let alloc_rows = allocators.map(v => `<tr><td>${v.type}</td><td>${byte_formatter(v.block)}</td><td>${byte_formatter(v.carrier)}</td></tr>`).join('');
    alloc_table.innerHTML = `
      <table class="process_table" style="text-align: left;">
        <thead><tr>
          <th>Type</th>
          <th>Block Size</th>
          <th>Carrier Size</th>
        </tr></thead>
        ${alloc_rows}
      </table>
    `;

  },
  display_table: e => {
    let data = e.data;
    let content = document.getElementById('content');
    let table = content.querySelector('table');
    let sorted = -1;
    let reverse = false;

    if( table ) {
      table.querySelectorAll('th').forEach( (e, i) => {
      if(e.className.includes('sorttable_sorted_reverse')){
        sorted = i;
        reverse = true;
      }else if(e.className.includes('sorttable_sorted')){
        sorted = i;
      }})
    }

    let formatted_tables = data.map( t => {
      let id = !isNaN(parseFloat(t.id)) && isFinite(t.id) ? t.id : '';
      return `<tr>
        <td><a href="javascript:window.show_table('${t.id}')">${t.name}</a></td>
        <td>${id}</td>
        <td>${t.size}</td>
        <td>${byte_formatter(t.memory)}</td>
        <td>${t.protection}</td>
        <td><a href="javascript:window.show_process('${t.owner}')">${t.owner}</a></td>
      </tr>`
    }).join('');

    content.innerHTML = `
      <table class="process_table" style="text-align: left;">
        <thead><tr>
          <th>Name</th>
          <th>ID</th>
          <th>Objects</th>
          <th>Size</th>
          <th>Protection</th>
          <th>Owner</th>
        </tr></thead>
        ${formatted_tables}
      </table>
    `;

    table = content.querySelector('table');
    sorttable.makeSortable(table);

    if( sorted >= 0 ){
      let th = table.getElementsByTagName('th')[sorted];
      sorttable.innerSortFunction.apply(th, []);
      if( reverse ) {
        sorttable.innerSortFunction.apply(th, []);
      }
    }
  },
  display_about: e => {
    let about = e.data;
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
  },
  show_process: (process, wobserver) => {
    new ProcessDetail(process, wobserver).show();
  },
  show_table: (table, wobserver) => {
    new TableDetail(table, wobserver).show();
  },
  show_custom: e => {
    let content = document.getElementById('content');

    content.innerHTML = show_custom_data(e.data);
  }
};

function show_custom_data(data, name = ''){
  if(data instanceof Array){
    return show_custom_array_table(data, name)
  } else {
    return show_custom_table(data, name);
  }
}

function show_custom_array_table(data, name = '') {
  if( data.length <= 0 ){
    return '';
  }

  let header =
    Object
    .keys(data[0])
    .map(key => `<th>${key}</th>`)
    .join('')

  let rows =
    data
    .map(row =>
      Object
      .keys(row)
      .map(key => `<td>${row[key]}</td>`)
      .join('')
    )
    .map(row => `<tr>${row}</tr>`)
    .join('');


  return `
    <table class="generic_array_table">
      <caption>${name}</caption>
      <thead>
        <tr>${header}</tr>
      </thead>
      ${rows}
    </table>
  `;
}

function show_custom_table(data, name = '') {
  let raw_table =
    !Object
    .keys(data)
    .map(key => data[key] instanceof Object)
    .reduce((a, b) => a || b);

  if( raw_table ){
    let rows =
      Object
      .keys(data)
      .map(key => `<tr><th>${key}</th><td>${data[key]}</td></tr>`)
      .join('');

    return `
      <table class="inline">
        <caption>${name}</caption>
        ${rows}
      </table>
    `;
  } else {
    let tables =
      Object
      .keys(data)
      .map(key => show_custom_data(data[key], key))
      .join('');

    return `
      <div>
        <span>${name}</span>
        ${tables}
      </div>
    `;
  }
}

export{ WobserverRender }
