/* Heizkalender Raumuebersicht: Checkbox fuer alle Termindetails.
 * Ohne dieses Skript bleiben alle Termine offen (open im HTML) und die
 * Checkbox versteckt. Betrifft nur details.hk-termin-details in
 * #hk-termine-tabelle.
 */
(function () {
  "use strict";

  function init() {
    var box = document.getElementById("hk-termine-toggle");
    var table = document.getElementById("hk-termine-tabelle");
    if (!box || !table || !table.querySelectorAll) { return; }

    var details = table.querySelectorAll("details.hk-termin-details");
    if (details.length === 0) { return; }

    var control = document.getElementById("hk-termine-control");

    /* Zustand aus den Details: alle offen, alle zu oder gemischt. */
    function update() {
      var open = 0;
      var i;
      for (i = 0; i < details.length; i++) {
        if (details[i].open) { open++; }
      }
      if (open === details.length) {
        box.indeterminate = false;
        box.checked = true;
      } else if (open === 0) {
        box.indeterminate = false;
        box.checked = false;
      } else {
        /* Mischzustand: naechster Klick oeffnet alle. */
        box.checked = false;
        box.indeterminate = true;
      }
    }

    box.addEventListener("change", function () {
      var target = box.checked;
      var i;
      for (i = 0; i < details.length; i++) {
        details[i].open = target;
      }
      update();
    });

    /* toggle feuert bei jeder Einzelumschaltung, auch bei Sammelaenderung. */
    for (var i = 0; i < details.length; i++) {
      details[i].addEventListener("toggle", update);
    }

    update();
    if (control) { control.removeAttribute("hidden"); }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
