$(function () {
  var bar = $("#bar");
  var front = $("#front");
  var back = $("#back");
  var url = $("#url");
  var inputTooltip = $("#input-tooltip");
  var sUrl = $("#s-url");
  var clipboard = new ClipboardJS("#copy");
  var linksClipboard = new ClipboardJS(".copy-btn");

  var copyTooltip = $("#copy-tooltip");

  clipboard.on("success", function () {
    copyTooltip.css("visibility", "visible");
    setTimeout(() => copyTooltip.css("visibility", "hidden"), 1000);
  });

  linksClipboard.on("success", function (e) {
    var btn = $(e.trigger);
    var originalText = btn.text();
    btn.text("Copied!");
    setTimeout(() => btn.text(originalText), 2000);
  });

  // Handle delete buttons
  $(".delete-btn").on("click", function () {
    var btn = $(this);
    var short = btn.data("short");

    if (confirm("Are you sure you want to delete this URL?")) {
      btn.prop("disabled", true);
      $.ajax({
        url: "/url/" + short,
        method: "DELETE",
        success: function () {
          btn.closest("tr").fadeOut(400, function () {
            $(this).remove();
            if ($("tbody tr").length === 0) {
              location.reload();
            }
          });
        },
        error: function () {
          alert("Failed to delete the URL. Please try again.");
          btn.prop("disabled", false);
        },
      });
    }
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
    var expression =
      /[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)?/gi;
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
    e.preventDefault();
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
