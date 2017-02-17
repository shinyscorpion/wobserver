import {Popup} from './popup.js';

class TableDetail {
  constructor(table, wobserver) {
    this.table = table;
    this.wobserver = wobserver;
  }

  show() {
    this.wobserver.client.command_promise('table/' + this.table)
    .then(e => {
      let table = e.data;
      if( table == 'error' ){
        Popup.show(`
        <div id="process_information">
        Can not show table.
        </div>
        `);
        return;
      }

      if( table.data.length <= 0 ){
        return Popup.show(`
        <div id="table_information">
          <span>Table has no content.</span>
        </div>
        `);
      }

      let table_data = table.data.map((row, index) => {
        let formatted_row = row.map(field => `<td><pre>${field}</pre></td>`).join('');
        return `<tr><th>${index+1}</th>${formatted_row}</tr>`;
      }).join('');


      Popup.show(`
      <div id="table_information">
        <span>Table Information:</span>
        <div>
          <table>
            ${table_data}
          </table>
        </div>
      </div>
      `);
    });
  }

  hide() {
    Popup.hide();
  }
}

export{ TableDetail }