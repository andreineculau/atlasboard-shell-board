/* global $ */
widget = {
  onFirstData: function(el, data) {
    var $el = $(el);

    if (data.config.css) {
      for (key in data.config.css) {
        $el.parent().css(key, data.config.css[key]);
      }
    }
    this.onFirstData = _.noop();
  },

  onData: function(el, data) {
    'use strict';
    var $el = $(el);

    this.onFirstData(el, data);

    $('.stdout', $el).html(data.htmlStdout || data.stdout);
    $('.stderr', $el).html(data.htmlStderr || data.stderr);
  },

  onError: function (el, data) {
    'use strict';
  }
};
