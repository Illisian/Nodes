#socket = io.connect('http://clive.illisian.com.au');
#socket.on 'news', (data) =>
#  console.log(data);

nAdmin = nAdmin || {};

requirejs.config {
  baseUrl: '/admin/'
  paths: {
    'jquery': 'js/jquery-2.0.3'
    'underscore': 'js/underscore-1.5.2.amd'
    'sirtrevor': 'js/sir-trevor-0.3.0'
    'eventable': 'js/eventable'
  }
  map: {
    '*': {
      'cssl': 'js/require.css' 
    }
  }
  shim: {
    jquery: {
      exports: '$'
    }
    underscore: {
      exports: '_'
    }
  }
}

requirejs [
  'jquery',
  'underscore',
  'sirtrevor',
  'eventable',
  'cssl!css/sir-trevor',
  'cssl!css/sir-trevor-icons'
], ($, _) =>
  $(document).ready () =>
    if $("body > form").length == 0
      $("body").wrapInner("<form></form>");
    
    nAdmin.editors = {}
    $("[nodes-placeholder]").each (index, el) =>
      nAdmin.editors[$(el).attr("nodes-placeholder")] = new SirTrevor.Editor({ el: $(el), blockTypes: ["Text", "Tweet", "Image"] });
      # now we need to hook up websockets and pull the sublayout information down for the page, and populate the trevor controls
      
      