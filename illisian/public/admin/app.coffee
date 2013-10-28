socket = io.connect('http://clive.illisian.com.au');
socket.on 'news', (data) =>
  console.log(data);
