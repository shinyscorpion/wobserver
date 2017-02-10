const chart_steps = 100;

function format_timestamp(timestamp, lastTimestamp = '') {
  if( Math.floor(lastTimestamp / 5) == Math.floor(timestamp / 5) ){
    return '       ';
  }
  lastTimestamp = timestamp;

  let date = new Date(timestamp * 1000);

  let minutes =  date.getMinutes();
  if( minutes < 10 ){
    minutes = '0' + minutes;
  }

  let seconds =  date.getSeconds();
  if( seconds < 10 ){
    seconds = '0' + seconds;
  }

  return date.getHours() + ':' + minutes + ':' + seconds;
}

function generate_data_sets(data){
  return data.map(item => {
    let color = 'rgba(' + item.r + ', ' + item.g + ', ' + item.b;

    return {
        label: item.label,
        type: 'line',
        fillColor: color + ', 0.1)',
        strokeColor: color + ', 0.8)',
        pointColor: color + ', 0)',
        pointStrokeColor: color + ', 0)',
        multiTooltipTemplate: item.label + ' - <%= value %>',
        data: Array(chart_steps).fill(0)
    }
  });
}

function generate_chart(id, data, unit, chartOwner) {
  let container = document.getElementById(id);
  container.className = 'wobserver-chart'
  let canvas = document.createElement('canvas');

  container.appendChild(canvas);

  let ctx = canvas.getContext('2d');

  let starting_data =
    {
      labels: Array(chart_steps).fill(''),
      datasets: generate_data_sets(data)
    };

  let options = {
    responsive: true,
    maintainAspectRatio: false,
    animationSteps: 1,
    scaleLabel: "<%=value%> " + unit,
    multiTooltipTemplate: "<%=value%> " + unit,
    scales: {
      xAxes: [{
        type: 'time',
        time: {
          displayFormats: {
            'millisecond': 'MMM DD',
            'second': 'MMM DD',
            'minute': 'MMM DD',
            'hour': 'MMM DD',
            'day': 'MMM DD',
            'week': 'MMM DD',
            'month': 'MMM DD',
            'quarter': 'MMM DD',
            'year': 'MMM DD'
          }
        }
      }]
    },
    legendTemplate: '<ul>'
                  +'<% for (var i=0; i<datasets.length; i++) { %>'
                    +'<li>'
                    +'<span style=\"background-color:<%= datasets[i].strokeColor %>\"></span>'
                    +'<% if (datasets[i].label) { %><%= datasets[i].label %><% } %>'
                  +'</li>'
                +'<% } %>'
              +'</ul>'
  };

  let chart = new Chart(ctx).Line(starting_data, options);

  let legend_div = document.createElement('div');
  legend_div.className = 'chart-legend';
  legend_div.innerHTML = chart.generateLegend();
  container.append(legend_div);

  container.chart = chartOwner;

  return chart;
}


class WobserverChart {
  constructor(id, data, unit) {
    this.chart = generate_chart(id, data, unit, this);
    this.last_timestamp = '';
  }

  update(data) {
    this.chart.addData(data, format_timestamp(data.timestamp, this.last_timestamp));
    this.chart.removeData();
    this.last_timestamp = data.timestamp;
  }
}

export{ WobserverChart }