$(function() {
  var url = $("#url");
  url.tooltip({ trigger: "manual", title: "Invalid url" });
  var sUrl = $("#s-url");
  var copy = $("#copy");
  copy.tooltip({ trigger: "manual", title: "copied" });
  var clipboard = new ClipboardJS("#copy");

  clipboard.on("success", function() {
    copy.tooltip("show");
    setTimeout(() => copy.tooltip("hide"), 1000);
  });

  var submitting = false;
  var submit = function() {
    if (submitting) {
      return;
    }
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
    submitting = true;
    $("#start").attr("disabled", "disabled");
    $.post("/url", { url: urlVal }, function(data) {
      $("#start").hide();
      $("#restart").show();
      var shortUrl = location.protocol + "//" + location.host + "/" + data;
      sUrl.val(shortUrl);
      sUrl.show();
      copy.show();
      url.hide();
      url.val("");
      submitting = false;
      $("#start").removeAttr("disabled");
    }).fail(function() {
      url.tooltip("show");
      submitting = false;
      $("#start").removeAttr("disabled");
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
    copy.hide();
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
