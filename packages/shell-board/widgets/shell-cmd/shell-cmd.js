/* global $ */
widget = {
  onFirstData: function(el, data) {
    var $el = $(el),
        key;

    if (data._.config.css) {
      for (key in data._.config.css) {
        $el.parent().css(key, data._.config.css[key]);
      }
    }
    this.onFirstData = _.noop();
  },

  onData: function(el, data) {
    'use strict';
    var $el = $(el);

    this.onFirstData(el, data);

    $('.stdout', $el).html(data.htmlStdout || data.stdout);
    $('.stderr', $el).html(data.htmlStderr || data.stderr);
  },

  onError: function (el, data) {
    'use strict';
    console.error(data);
  }
};
