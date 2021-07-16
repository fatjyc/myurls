$(function () {
  var bar = $("#bar");
  var front = $("#front");
  var back = $("#back");
  var url = $("#url");
  var inputTooltip = $("#input-tooltip");
  var sUrl = $("#s-url");
  var clipboard = new ClipboardJS("#copy");

  var copyTooltip = $("#copy-tooltip");

  clipboard.on("success", function () {
    copyTooltip.css("visibility", "visible");
    setTimeout(() => copyTooltip.css("visibility", "hidden"), 1000);
  });

  var submitting = false;
  var submit = function () {
    if (submitting) {
      return;
    }
    var urlVal = url.val().trim();
    if (urlVal.length === 0) {
      inputTooltip.css("visibility", "visible");
      return;
    }
    var expression = /[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)?/gi;
    var regex = new RegExp(expression);
    if (!urlVal.match(regex)) {
      inputTooltip.css("visibility", "visible");
      return;
    }
    submitting = true;
    $("#start").attr("disabled", "disabled");
    $.post("/url", { url: urlVal }, function (data) {
      var shortUrl = location.protocol + "//" + location.host + "/" + data;
      sUrl.val(shortUrl);
      url.val("");
      submitting = false;
      $("#start").removeAttr("disabled");
      bar.toggleClass("flipped");
      // front.toggleClass("show");
      // back.toggleClass("show");
    }).fail(function () {
      inputTooltip.css("visibility", "visible");
      submitting = false;
      $("#start").removeAttr("disabled");
    });
  };

  $("#start").on("click", function (e) {
    submit();
  });

  $("#restart").on("click", function () {
    sUrl.val("");
    url.val("");
    bar.toggleClass("flipped");
    // back.toggleClass("show");
    // front.toggleClass("show");
  });

  url.on("input", function (e) {
    inputTooltip.css("visibility", "hidden");
  });

  url.on("keyup", function (e) {
    if (e.which === 13) {
      submit();
    }
  });
});
