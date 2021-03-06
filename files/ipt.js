// (function(){
// https://purge.jsdelivr.net/gh/VPSDance/scripts@main/files/ipt.js

// cp(text)
window.__cp = (text) => {
  const dummy = document.createElement('textarea');
  document.body.appendChild(dummy);
  dummy.value = text;
  dummy.select();
  document.execCommand('copy');
  document.body.removeChild(dummy);
}

window.__tr = () => {
  // const name = $('#note :selected').text();
  let html = ``;
  const lines = $('#trace tbody tr').map((_, line) => {
    let [ttl, ip, host, location, as, time] = $(line).find('td').toArray().map(o => o.innerText.split('\n'));
    const valIndex = ip.findLastIndex(o => !!o && o !== '*');
    const val = (arr) => arr[valIndex] || arr[0];
    [ttl, host, ip, time, as, location] = [val(ttl), val(host), val(ip), val(time), val(as), val(location)];
    ip = (ip === host ? '' : ` (${ip})`);
    time = time.split(' / ')[1] || time;
    return host === '*' ? `${ttl}  *` : `${ttl}  ${host}${ip}  ${time}ms  ${as}  ${location}`;
  });
  html = lines.toArray().reduce((acc, curr) => {
    [last = ''] = acc.slice(-1)
    if (last.slice(-1) + curr.slice(-1) === '**') acc.pop();
    acc.push(curr);  
    return acc;
  }, []).join('\n');
  console.warn(html);
  // __cp(html);
  return html;
}
// tr();

window.__process = (item) => new Promise((resolve, reject) => {
  const cb = (text) => {
    clearTimeout(item._t);
    clearInterval(item._i);
    resolve({ ...item, text });
  }
  $('select[name="id"]').val(item.id);
  // return setTimeout(() => cb('test ' + item.name), 2 * 1000);
  try {
    $('#btn').trigger('click');
  } catch (error) { console.warn(error); }
  try {
    $('#ps').submit();
  } catch (error) { console.warn(error); }
  const l = $('#load');
  item._t = setTimeout(() => cb(''), 1000 * 60 * 2); // timeout
  item._i = setInterval(() => {
    const done = l.is(':hidden');
    if (!done) return;
    cb($('#trace tbody tr').length > 1 ? __tr() : '');
  }, 1000);
});
window.__queue = (items) => {
  if (!$('#ip').val()) return Promise.reject('no ip');
  let arr = [];
  const run = async () => {
    for(let o of items) {
      let v = await __process(o);
      arr.push(v);
    }
    return arr;
  }
  return run();
};
window.__init = () => {
  const form = $('#ps');
  form.next('button').remove();
  form.after('<button onclick="__fetch()">test</button>');
  $('select[name="t"]').val('T');
  // $('select[name="id"]').val();
}
__init();

__IDS__ = [
  {id: '896', name: '????????????'},
  {id: '502', name: '????????????'},
  {id: '764', name: '????????????'},
  {id: '11', name: '????????????'},

  {id: '1240', name: '????????????9929'},
  {id: '503', name: '????????????'},
  {id: '765', name: '????????????'},
  // {id: '1078', name: '????????????'},
  {id: '12', name: '????????????'},
  // {id: '662', name: '????????????'},

  {id: '424', name: '????????????'},
  {id: '766', name: '????????????'},
  {id: '924', name: '????????????'},
  // {id: '946', name: '????????????'},
];
// __IDS__ = [ {id: '503', name: '????????????'}, {id: '424', name: '????????????'}, ];
window.__fetch = () => __queue(__IDS__).then(arr => {
  // console.warn(arr);
  const ip = $('#ip').val();
  const ipMask = ip.split('.').slice(0, 2).concat('*', '*').join('.');
  const ipReg = new RegExp(`\\b${ip.split('.').join('\\.')}\\b`, 'g');
  const data = [{text: `traceroute to ${ip}, 30 hops max, 32 byte packets` }, ...arr].filter(o => !!o.text)
    .map(({ name, text }) => [name, text].filter(o => !!o).join('\n')).join(`\n${new Array(50).join('-')}\n`)
    .replace(ipReg, ipMask);
  console.warn(data);
  window.__d__ = data;
  $('#map_view').before('<button onclick="__cp(__d__)">cp</button>');
});


// }());
