$(function() {
  $("#title").text(location.host);

  var url = $("#url");
  url.tooltip({ trigger: "manual", title: "Invalid url" });
  var sUrl = $("#s-url");

  var submit = function() {
    var urlVal = url.val().trim();
    if (urlVal.length === 0) {
      url.tooltip("show");
      return;
    }
    var expression = /[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)?/gi;
    var regex = new RegExp(expression);
    if (!urlVal.match(regex)) {
      url.tooltip("show");
      return;
    }
    $.post("/url", { url: urlVal }, function(data) {
      $("#start").hide();
      $("#restart").show();
      var shortUrl = location.protocol + "//" + location.host + "/" + data;
      sUrl.val(shortUrl);
      sUrl.show();
      url.hide();
      url.val("");
    });
  };

  $("#url-form").on("submit", function(e) {
    e.preventDefault();
    submit();
  });

  $("#restart").on("click", function() {
    $("#start").show();
    $("#restart").hide();
    sUrl.val("");
    url.val("");
    sUrl.hide();
    url.show();
  });

  url.on("input", function(e) {
    url.tooltip("hide");
  });

  url.on("keyup", function(e) {
    if (e.which === 13) {
      submit();
    }
  });
});
