import {Popup} from './popup.js';

function format_pid_url(pid) {
  if( pid.startsWith('#Port') ){
    return pid
  }

  return `<li><a href="javascript:window.show_process('${pid}')">${pid}</a></li>`
}

class ProcessDetail {
  constructor(process, wobserver) {
    this.process = process;
    this.wobserver = wobserver;
  }

  show() {
    this.wobserver.client.command_promise('process/' + this.process)
    .then(e => {
      let process = e.data;
      if( process == 'error' ){
        Popup.show(`
          <div id="process_information">
            <span>Process information:</span>
            <p>Process is either dead or protected and therefore can not be shown.</p>
          </div>
        `);
        return;
      }
      // <a href="javascript:window.show_process('${process.pid}')">
      let links = process.relations.links.map(pid => format_pid_url(pid) ).join('');
      let ancestors = process.relations.ancestors.map(pid => format_pid_url(pid) ).join('');
      let monitors = '';

      Popup.show(`
      <div id="process_information">
        <span>Process information:</span>
        <table>
          <caption>Overview</caption>
          <tr><th>Process id:</th><td>${process.pid}</td></tr>
          <tr><th>Registered name:</th><td>${process.registered_name}</td></tr>
          <tr><th>Status:</th><td>${process.meta.status}</td></tr>
          <tr><th>Message Queue Length:</th><td>${process.message_queue_len}</td></tr>
          <tr><th>Group Leader:</th><td><a href="javascript:window.show_process('${process.relations.group_leader}')">${process.relations.group_leader}</a></td></tr>
        </table>
        <table>
          <caption>Memory</caption>
          <tr><th>Total:</th><td>${process.memory.total}</td></tr>
          <tr><th>Heap Size:</th><td>${process.memory.heap_size}</td></tr>
          <tr><th>Stack Size:</th><td>${process.memory.stack_size}</td></tr>
          <tr><th>GC Min Heap Size:</th><td>${process.memory.gc_min_heap_size}</td></tr>
          <tr><th>GC FullSweep After:</th><td>${process.memory.gc_full_sweep_after}</td></tr>
        </table>
        <div id="process_relations">
          <div>
            <span>Links</span>
            <ul>
              ${links}
            </ul>
          </div>
          <div>
            <span>Ancestors</span>
            <ul>
              ${ancestors}
            </ul>
          </div>
          <div>
            <span>Monitors</span>
            <ul>
              ${monitors}
            </ul>
          </div>
        </div>
        <span>State</span>
        <pre>${process.state}</pre>
      </div>
      `);
    });
  }

  hide() {
    Popup.hide();
  }
}

export{ ProcessDetail }