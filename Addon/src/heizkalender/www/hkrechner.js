// Heizkalender-Addon: Vorheizzeit-Rechner (clientseitige Logik)
// Berechnungslogik entspricht HK-Skript 2, Zeilen 354-573

// AT-Grenzen der HK2-Kurve (8 Stuetzwerte)
var AT_GRENZEN = [-10, -5, 0, 8, 10, 12, 15, 17.5];

function linearInterpolate(at, kurve) {
    // Gibt die AT-abhaengige Vorheizzeit in Minuten zurueck (>= 0)
    var v = parseFloat(at);
    if (v <= AT_GRENZEN[0]) return Math.max(0, kurve[0]);
    if (v >= AT_GRENZEN[7]) return Math.max(0, kurve[7]);
    for (var i = 0; i < 7; i++) {
        if (v >= AT_GRENZEN[i] && v < AT_GRENZEN[i+1]) {
            var lx = AT_GRENZEN[i], ux = AT_GRENZEN[i+1];
            var ly = kurve[i],      uy = kurve[i+1];
            var result = ((uy - ly) / (ux - lx)) * (v - lx) + ly;
            return Math.max(0, result);
        }
    }
    return 0;
}

function parseKurve(s) {
    var parts = s.split(";");
    if (parts.length !== 8) return null;
    var vals = [];
    for (var i = 0; i < 8; i++) {
        var n = parseFloat(parts[i]);
        if (isNaN(n) || n < 0) return null;
        vals.push(n);
    }
    return vals;
}


// ---------------------------------------------------------------------------
// Validierung
// ---------------------------------------------------------------------------
function validateFields() {
    var ok = true;
    ok = validateNum("hkr-at",        -40,  40,   true)  && ok;
    ok = validateNum("hkr-grundtemp",   5,  30,   true)  && ok;
    ok = validateNum("hkr-atg",       -40,  40,   false) && ok;
    ok = validateNum("hkr-ist",       -40,  40,   true)  && ok;
    ok = validateNum("hkr-ziel",        5,  40,   true)  && ok;
    ok = validateNum("hkr-gt",          5,  30,   true)  && ok;
    ok = validateNum("hkr-vhz",         0, 960,   true)  && ok;
    ok = validateNum("hkr-kv",          0, 960,   true)  && ok;
    ok = validateNum("hkr-faktor1",  0.20,  5.0,  true)  && ok;
    ok = validateNum("hkr-mindest",     1, 480,   true)  && ok;
    ok = validateNum("hkr-ka",        0.3,  1.0,  true)  && ok;
    ok = validateKurve()                                  && ok;

    // Kreuzvalidierung ziel > gt
    var ziel = parseFloat(document.getElementById("hkr-ziel").value);
    var gt   = parseFloat(document.getElementById("hkr-gt").value);
    if (!isNaN(ziel) && !isNaN(gt)) {
        if (ziel <= gt) {
            setErr("hkr-ziel", "Ziel muss groesser als Grundtemp sein");
            setErr("hkr-gt",   "Grundtemp muss kleiner als Ziel sein");
            ok = false;
        }
    }
    return ok;
}

function validateNum(id, min, max, required) {
    var el = document.getElementById(id);
    var v  = el.value.trim();
    if (v === "") {
        if (required) { setErr(id, "Pflichtfeld"); return false; }
        clearErr(id); return true;
    }
    var n = parseFloat(v);
    if (isNaN(n)) { setErr(id, "Keine gueltige Zahl"); return false; }
    if (n < min || n > max) {
        setErr(id, "Bereich " + min + ".." + max); return false;
    }
    clearErr(id); return true;
}

function validateKurve() {
    var el = document.getElementById("hkr-kurve");
    var v  = el.value.trim();
    if (v === "") { setErr("hkr-kurve", "Pflichtfeld"); return false; }
    if (v.length > 60) { setErr("hkr-kurve", "Zu lang"); return false; }
    if (parseKurve(v) === null) {
        setErr("hkr-kurve", "8 Zahlen >= 0, semikolongetrennt"); return false;
    }
    clearErr("hkr-kurve"); return true;
}

function setErr(id, msg) {
    var el = document.getElementById(id);
    var er = document.getElementById(id + "-err");
    if (el) el.classList.add("hkr-invalid");
    if (er) er.textContent = msg;
}

function clearErr(id) {
    var el = document.getElementById(id);
    var er = document.getElementById(id + "-err");
    if (el) el.classList.remove("hkr-invalid");
    if (er) er.textContent = "";
}

// ---------------------------------------------------------------------------
// Berechnung
// ---------------------------------------------------------------------------
function berechnen() {
    if (!validateFields()) {
        document.getElementById("hkr-gruppe-kurve").style.display = "none";
        document.getElementById("hkr-gruppe-ergebnis").style.display = "none";
        document.getElementById("hkr-gruppe-zeitanteile").style.display = "none";
        document.getElementById("hkr-gruppe-verlauf").style.display = "none";
        document.getElementById("hkr-gruppe-vergleich").style.display = "none";
        return;
    }

    var at       = parseFloat(document.getElementById("hkr-at").value);
    var atgEl    = document.getElementById("hkr-atg");
    var atg      = (atgEl && atgEl.value !== "") ? parseFloat(atgEl.value) : NaN;
    var ist      = parseFloat(document.getElementById("hkr-ist").value);
    var ziel     = parseFloat(document.getElementById("hkr-ziel").value);
    var gt       = parseFloat(document.getElementById("hkr-gt").value);
    var vhz      = parseFloat(document.getElementById("hkr-vhz").value);
    var kv       = parseFloat(document.getElementById("hkr-kv").value);
    var f1       = parseFloat(document.getElementById("hkr-faktor1").value);
    var mindest  = parseFloat(document.getElementById("hkr-mindest").value);
    var ka       = parseFloat(document.getElementById("hkr-ka").value);
    var kurve    = parseKurve(document.getElementById("hkr-kurve").value);

    // faktor1HK2Kurve clippen
    f1 = Math.max(0.20, Math.min(5.0, f1));

    // AT-abhaengige Vorheizzeit (roh, Minuten)
    var atRoh_min = linearInterpolate(at, kurve);

    // faktor2HeizBedarf (Zwei-Geraden-Modell)
    var f2 = 1.0;
    if ((ziel - gt) !== 0) {
        var istClip = Math.min(ist, ziel);
        var mitte   = gt + (ziel - gt) / 2;
        if (ist < mitte) {
            f2 = 1.0 - ka * ((istClip - gt) / (ziel - gt));
        } else {
            f2 = (2.0 - ka) * (1.0 - ((istClip - gt) / (ziel - gt)));
        }
    }

    // Skalierte Anteile (Minuten, positiv)
    var vhzRoh_min  = vhz + kv;
    var vhzSkal_min = vhzRoh_min * f2;
    var atSkal_min  = f1 * f2 * atRoh_min;

    // Gesamtvorheizzeit
    var gesamt_min  = vhzSkal_min + atSkal_min;
    var effektiv_min = Math.max(gesamt_min, mindest);

    // Erwaermungsquotient (Grad/h), Sonderfall gesamt_min == 0
    var quotient = effektiv_min > 0 ? (ziel - ist) / (effektiv_min / 60) : 0;

    // ---------------------------------------------------------------------------
    // Ergebnis-Tabelle befuellen
    // ---------------------------------------------------------------------------
    setText("hkr-r-vhz-roh",    fmtDE(vhzRoh_min, 1));
    setText("hkr-r-at-roh",     fmtDE(atRoh_min, 1));
    setText("hkr-r-f1",         fmtDE(f1, 2));
    setText("hkr-r-f2",         fmtDE(f2, 3));
    setText("hkr-r-vhz-skal",   fmtDE(vhzSkal_min, 1));
    setText("hkr-r-at-skal",    fmtDE(atSkal_min, 1));
    setText("hkr-r-gesamt-roh", fmtDE(gesamt_min, 1));
    setText("hkr-r-mindest",    fmtDE(mindest, 0));

    var effEl = document.getElementById("hkr-r-effektiv");
    effEl.textContent = fmtDE(effektiv_min, 1);
    effEl.className = "";

    setText("hkr-r-quotient", fmtDE(quotient, 2));

    document.getElementById("hkr-gruppe-kurve").style.display = "";
    document.getElementById("hkr-gruppe-ergebnis").style.display = "";
    document.getElementById("hkr-gruppe-zeitanteile").style.display = "";
    document.getElementById("hkr-gruppe-verlauf").style.display = "";

    var vergleichVerfuegbar = (typeof HKR_RAEUME !== "undefined" && HKR_RAEUME.length > 1);
    document.getElementById("hkr-gruppe-vergleich").style.display = vergleichVerfuegbar ? "" : "none";

    // ---------------------------------------------------------------------------
    // Canvas zeichnen
    // ---------------------------------------------------------------------------
    setTimeout(function() {
        zeichneF2Kurve(gt, ziel, ka, ist, f2);
        zeichneZeitbalken(vhzRoh_min, atRoh_min, f1, f2, vhzSkal_min, atSkal_min, mindest, effektiv_min, gesamt_min);
        zeichneKurvendiagramm(kurve, f1, f2, gt, ziel, at, atg);
        zeichneVerlauf(gt, ziel, ist, ka, effektiv_min);
        var aktiverRaum = "";
        var sel = document.getElementById("hkr-raum");
        if (sel) aktiverRaum = sel.value;
        zeichneVergleich(at, kv, kurve, ka, ist, aktiverRaum);
    }, 0);
}

function setText(id, val) {
    var el = document.getElementById(id);
    if (el) el.textContent = val;
}

function fmtDE(n, stellen) {
    return n.toFixed(stellen).replace(".", ",");
}

// ---------------------------------------------------------------------------
// Canvas 1: Heizbedarf-Kurve
// ---------------------------------------------------------------------------
function zeichneF2Kurve(gt, ziel, ka, ist, f2Aktuell) {
    var canvas = document.getElementById("hkr-canvas-f2");
    if (!canvas || !canvas.getContext) return;

    var dpr   = window.devicePixelRatio || 1;
    var avail = canvas.parentElement ? canvas.parentElement.clientWidth - 24 : 0;
    var cssW  = avail > 200 ? avail : canvas.width;
    var cssH  = Math.round(cssW * 0.4);
    canvas.width  = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
    canvas.style.width  = cssW + "px";
    canvas.style.height = cssH + "px";

    var W = canvas.width, H = canvas.height;
    var ctx = canvas.getContext("2d");
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, cssW, cssH);

    var W = cssW, H = cssH;
    var pad = {l: 45, r: 15, t: 15, b: 35};
    var cw = W - pad.l - pad.r;
    var ch = H - pad.t - pad.b;

    function xPos(t) { return pad.l + (t - gt) / (ziel - gt) * cw; }
    function yPos(f) { return pad.t + (1 - f) * ch; }

    // Hintergrund
    ctx.fillStyle = "#f8f8f8";
    ctx.fillRect(pad.l, pad.t, cw, ch);

    // Achsen
    ctx.strokeStyle = "#888";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(pad.l, pad.t); ctx.lineTo(pad.l, pad.t + ch);
    ctx.lineTo(pad.l + cw, pad.t + ch);
    ctx.stroke();

    // y-Achse Beschriftung
    ctx.fillStyle = "#555";
    ctx.font = "11px sans-serif";
    ctx.textAlign = "right";
    for (var f = 0; f <= 1.0; f += 0.25) {
        var yp = yPos(f);
        ctx.fillText(fmtDE(f, 2), pad.l - 4, yp + 4);
        ctx.strokeStyle = "#ddd";
        ctx.beginPath(); ctx.moveTo(pad.l, yp); ctx.lineTo(pad.l + cw, yp); ctx.stroke();
    }

    // x-Achse Beschriftung
    ctx.textAlign = "center";
    ctx.fillStyle = "#555";
    ctx.fillText(fmtDE(gt, 1) + "\u00b0", pad.l, pad.t + ch + 20);
    var mitte = gt + (ziel - gt) / 2;
    ctx.fillText(fmtDE(mitte, 1) + "\u00b0", xPos(mitte), pad.t + ch + 20);
    ctx.fillText(fmtDE(ziel, 1) + "\u00b0", pad.l + cw, pad.t + ch + 20);

    // Kurve (zwei Geraden)
    ctx.strokeStyle = "#2266cc";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(xPos(gt), yPos(1.0));
    // Knickpunkt
    var f2Mitte;
    if ((ziel - gt) !== 0) {
        var istClipMitte = Math.min(mitte, ziel);
        f2Mitte = 1.0 - ka * ((istClipMitte - gt) / (ziel - gt));
    } else {
        f2Mitte = 1.0;
    }
    ctx.lineTo(xPos(mitte), yPos(f2Mitte));
    ctx.lineTo(xPos(ziel),  yPos(0.0));
    ctx.stroke();

    // Vertikale Linie am IST-Wert
    var istClamp = Math.max(gt, Math.min(ziel, ist));
    var xIst = xPos(istClamp);
    ctx.strokeStyle = "#cc4400";
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 3]);
    ctx.beginPath();
    ctx.moveTo(xIst, pad.t); ctx.lineTo(xIst, pad.t + ch);
    ctx.stroke();
    ctx.setLineDash([]);

    // Punkt auf der Kurve
    var yF2 = yPos(f2Aktuell);
    ctx.fillStyle = "#cc4400";
    ctx.beginPath();
    ctx.arc(xIst, yF2, 5, 0, 2 * Math.PI);
    ctx.fill();

    // Beschriftung des Punktes
    ctx.fillStyle = "#cc4400";
    ctx.font = "bold 11px sans-serif";
    ctx.textAlign = "left";
    var labelX = xIst + 8;
    if (labelX + 50 > W) labelX = xIst - 58;
    ctx.fillText("f2=" + fmtDE(f2Aktuell, 3), labelX, yF2 - 4);

    // Achsenbeschriftung
    ctx.fillStyle = "#333";
    ctx.font = "11px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("IST-Temperatur (\u00b0C)", pad.l + cw / 2, H - 2);
    ctx.save();
    ctx.translate(12, pad.t + ch / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText("Heizbedarf-Faktor", 0, 0);
    ctx.restore();
}

// ---------------------------------------------------------------------------
// Canvas 3: Heizkurven-Diagramm (HK2, f1*HK2, f1*f2*HK2 ueber AT)
// ---------------------------------------------------------------------------
function zeichneKurvendiagramm(kurve, f1, f2, gt, ziel, at, atg) {
    var canvas = document.getElementById("hkr-canvas-kurven");
    if (!canvas || !canvas.getContext) return;

    var dpr   = window.devicePixelRatio || 1;
    var avail = canvas.parentElement ? canvas.parentElement.clientWidth - 24 : 0;
    var cssW  = avail > 200 ? avail : canvas.width;
    var cssH  = Math.round(cssW * 0.35);
    canvas.width  = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
    canvas.style.width  = cssW + "px";
    canvas.style.height = cssH + "px";

    var W = cssW, H = cssH;
    var ctx = canvas.getContext("2d");
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, W, H);

    var pad = {l: 44, r: 16, t: 16, b: 30};
    var cw = W - pad.l - pad.r;
    var ch = H - pad.t - pad.b;

    // X-Achse: AT von -12 bis 20
    var atMin = -12, atMax = 20;
    function xPos(a) { return pad.l + (a - atMin) / (atMax - atMin) * cw; }

    // Y-Achse: 0 bis max(kurve) * f1 * 1.1, mind. 10
    var kurveMax = 0;
    for (var i = 0; i < kurve.length; i++) if (kurve[i] > kurveMax) kurveMax = kurve[i];
    var yMax = Math.max(kurveMax * f1 * 1.15, 10);
    function yPos(v) { return pad.t + ch - (v / yMax) * ch; }

    // Hintergrund
    ctx.fillStyle = "#fafafa";
    ctx.fillRect(pad.l, pad.t, cw, ch);

    // Gitternetz Y
    ctx.strokeStyle = "#e0e0e0";
    ctx.lineWidth = 1;
    ctx.font = "11px sans-serif";
    ctx.fillStyle = "#666";
    ctx.textAlign = "right";
    var yStep = yMax <= 60 ? 10 : yMax <= 120 ? 20 : yMax <= 300 ? 60 : 120;
    for (var yv = 0; yv <= yMax; yv += yStep) {
        var yp = yPos(yv);
        ctx.beginPath(); ctx.moveTo(pad.l, yp); ctx.lineTo(pad.l + cw, yp); ctx.stroke();
        ctx.fillText(Math.round(yv), pad.l - 4, yp + 4);
    }

    // Gitternetz X (AT-Grenzen)
    ctx.textAlign = "center";
    for (var gi = 0; gi < AT_GRENZEN.length; gi++) {
        var xg = xPos(AT_GRENZEN[gi]);
        ctx.strokeStyle = "#e8e8e8";
        ctx.beginPath(); ctx.moveTo(xg, pad.t); ctx.lineTo(xg, pad.t + ch); ctx.stroke();
        ctx.fillStyle = "#888";
        ctx.fillText(fmtDE(AT_GRENZEN[gi], 0), xg, pad.t + ch + 14);
    }

    // Balken: HK2-Stuetzwerte (links) und f1*HK2 (rechts)
    var barW = cw / (atMax - atMin) * 0.5;
    for (var bi = 0; bi < AT_GRENZEN.length; bi++) {
        var bxC = xPos(AT_GRENZEN[bi]) - barW / 2;
        var bhL = (kurve[bi] / yMax) * ch;
        var bhR = (kurve[bi] * f1 / yMax) * ch;
        ctx.lineWidth = 1;
        // Blauer Balken: HK2 (unten)
        ctx.fillStyle = "#ddeef9";
        ctx.fillRect(bxC, yPos(kurve[bi]), barW, bhL);
        ctx.strokeStyle = "#2e86c1";
        ctx.strokeRect(bxC, yPos(kurve[bi]), barW, bhL);
        // Oranger Balken: f1*HK2 (darueber gestapelt, nur Differenzanteil)
        var bhDiff = (kurve[bi] * f1 - kurve[bi]) / yMax * ch;
        ctx.fillStyle = "#ffeedd";
        ctx.fillRect(bxC, yPos(kurve[bi] * f1), barW, bhDiff);
        ctx.strokeStyle = "#e67e22";
        ctx.strokeRect(bxC, yPos(kurve[bi] * f1), barW, bhDiff);
    }

    // Linie 1: HK2(T_at) interpoliert (blau)
    ctx.strokeStyle = "#2e86c1";
    ctx.lineWidth = 2;
    ctx.beginPath();
    var steps = 200;
    for (var s = 0; s <= steps; s++) {
        var a = atMin + (atMax - atMin) * s / steps;
        var v = linearInterpolate(a, kurve);
        if (s === 0) ctx.moveTo(xPos(a), yPos(v));
        else         ctx.lineTo(xPos(a), yPos(v));
    }
    ctx.stroke();

    // Linie 2: f1 * HK2(T_at) (orange)
    ctx.strokeStyle = "#e67e22";
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (var s2 = 0; s2 <= steps; s2++) {
        var a2 = atMin + (atMax - atMin) * s2 / steps;
        var v2 = f1 * linearInterpolate(a2, kurve);
        if (s2 === 0) ctx.moveTo(xPos(a2), yPos(v2));
        else          ctx.lineTo(xPos(a2), yPos(v2));
    }
    ctx.stroke();

    // Linie 3: f1 * f2 * HK2(T_at) (gruen, f2 haengt von T_ist ab, nicht von AT)
    ctx.strokeStyle = "#cc2200";
    ctx.lineWidth = 2;
    ctx.setLineDash([]);
    ctx.beginPath();
    for (var s3 = 0; s3 <= steps; s3++) {
        var a3 = atMin + (atMax - atMin) * s3 / steps;
        var v3 = f1 * f2 * linearInterpolate(a3, kurve);
        if (s3 === 0) ctx.moveTo(xPos(a3), yPos(v3));
        else          ctx.lineTo(xPos(a3), yPos(v3));
    }
    ctx.stroke();
    ctx.setLineDash([]);

    // Aktuelle AT (grüne Linie)
    var xAt = xPos(at);
    ctx.strokeStyle = "#1a7a3a";
    ctx.lineWidth = 1.5;
    ctx.setLineDash([4, 3]);
    ctx.beginPath();
    ctx.moveTo(xAt, pad.t);
    ctx.lineTo(xAt, pad.t + ch);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = "#1a7a3a";
    ctx.font = "11px sans-serif";
    ctx.textAlign = xAt > W - 60 ? "right" : "left";
    ctx.fillText("AT=" + fmtDE(at, 1), xAt + (xAt > W - 60 ? -4 : 4), pad.t + 12);

    // AT-Grenze (rote gestrichelte Linie, nur wenn definiert und im Darstellungsbereich)
    if (!isNaN(atg) && atg >= atMin && atg <= atMax) {
        var xAtg = xPos(atg);
        ctx.strokeStyle = "#c0392b";
        ctx.lineWidth = 1.5;
        ctx.setLineDash([4, 3]);
        ctx.beginPath();
        ctx.moveTo(xAtg, pad.t);
        ctx.lineTo(xAtg, pad.t + ch);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = "#c0392b";
        ctx.font = "11px sans-serif";
        ctx.textAlign = xAtg > W - 60 ? "right" : "left";
        ctx.fillText("ATG=" + fmtDE(atg, 1), xAtg + (xAtg > W - 60 ? -4 : 4), pad.t + 24);
    }

    // Marker: Schnittpunkt AT und VLZ_eff
    var vlzEffAtAt = f1 * f2 * linearInterpolate(at, kurve);
    ctx.fillStyle = "#cc2200";
    ctx.strokeStyle = "#fff";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(xAt, yPos(vlzEffAtAt), 5, 0, 2 * Math.PI);
    ctx.fill();
    ctx.stroke();

    // Achsenbeschriftung
    ctx.fillStyle = "#555";
    ctx.font = "11px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Au\u00dfentemperatur (\u00b0C)", pad.l + cw / 2, H - 2);
    ctx.save();
    ctx.translate(11, pad.t + ch / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText("Vorheizzeit (min)", 0, 0);
    ctx.restore();
}

// ---------------------------------------------------------------------------
// Canvas 2: Zeitanteile als horizontales Balkendiagramm
// ---------------------------------------------------------------------------
function zeichneZeitbalken(vhzRoh, atRoh, f1, f2, vhzSkal, atSkal, mindest, effektiv, gesamt) {
    var canvas = document.getElementById("hkr-canvas-zeit");
    if (!canvas || !canvas.getContext) return;

    var dpr   = window.devicePixelRatio || 1;
    var avail = canvas.parentElement ? canvas.parentElement.clientWidth - 24 : 0;
    var cssW  = avail > 200 ? avail : canvas.width;
    var cssH  = 133;
    canvas.width  = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
    canvas.style.width  = cssW + "px";
    canvas.style.height = cssH + "px";

    var W = cssW, H = cssH;
    var ctx = canvas.getContext("2d");
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, W, H);

    var pad = {l: 10, r: 10, t: 8, b: 15};
    var cw = W - pad.l - pad.r;
    var atSkalRoh = f1 * atRoh; // f1 * HK2, noch ohne f2
    // Skalierung: laengster relevanter Wert bestimmt die Breite
    var maxVal = Math.max(vhzRoh + atSkalRoh, vhzSkal + atSkal, effektiv, mindest, 1);
    function xLen(min) { return min / maxVal * cw; }

    var rowH   = 30;
    var rowGap = 10;
    var y1 = pad.t;               // Zeile 1: Rohwerte (ohne f2)
    var y2 = y1 + rowH + rowGap;  // Zeile 2: Skaliert (mit f2)
    var y3 = y2 + rowH + rowGap;  // Zeile 3: Effektiv

    // Zeichnet Text mit zwei Subscripts: pre + sub1 + mid + sub2 + post
    // parts: [{t, s}] wobei s:true = kleines Subscript, s:false = normaler Text
    function drawParts(bx, by, bw, bh, parts, color) {
        var sizes = parts.map(function(p) {
            ctx.font = p.s ? "10px sans-serif" : "14px sans-serif";
            return ctx.measureText(p.t).width;
        });
        var totalW = sizes.reduce(function(a, b) { return a + b; }, 0);
        var tx = bx + (bw - totalW) / 2;
        if (tx < bx + 2) tx = bx + 2;
        var ty = by + bh / 2 + 4;
        ctx.fillStyle = color;
        ctx.textAlign = "left";
        for (var i = 0; i < parts.length; i++) {
            ctx.font = parts[i].s ? "10px sans-serif" : "14px sans-serif";
            ctx.fillText(parts[i].t, tx, parts[i].s ? ty + 3 : ty);
            tx += sizes[i];
        }
    }

    ctx.font = "14px sans-serif";

    // --- Zeile 1: Rohwerte (vor f2) ---
    var x = pad.l;
    if (vhzRoh > 0) {
        ctx.fillStyle = "#2e86c1";
        ctx.fillRect(x, y1, xLen(vhzRoh), rowH);
        if (xLen(vhzRoh) >= 30) {
            drawParts(x, y1, xLen(vhzRoh), rowH,
                [{t:"V",s:false},{t:"raum",s:true},{t:"+V",s:false},{t:"global",s:true},{t:" = "+fmtDE(vhzRoh,1),s:false}], "#fff");
        }
        x += xLen(vhzRoh);
    }
    if (atSkalRoh > 0) {
        ctx.fillStyle = "#e67e22";
        ctx.fillRect(x, y1, xLen(atSkalRoh), rowH);
        if (xLen(atSkalRoh) >= 30) {
            drawParts(x, y1, xLen(atSkalRoh), rowH,
                [{t:"f",s:false},{t:"1",s:true},{t:" * HK2 = "+fmtDE(atSkalRoh,1),s:false}], "#fff");
        }
        x += xLen(atSkalRoh);
    }

    // --- Zeile 2: Skaliert (nach f2) ---
    x = pad.l;
    if (vhzSkal > 0) {
        ctx.fillStyle = "#ddeef9";
        ctx.fillRect(x, y2, xLen(vhzSkal), rowH);
        if (xLen(vhzSkal) >= 40) {
            drawParts(x, y2, xLen(vhzSkal), rowH,
                [{t:"V",s:false},{t:"raum",s:true},{t:"+V",s:false},{t:"global",s:true},{t:" * f",s:false},{t:"2",s:true},{t:" = "+fmtDE(vhzSkal,1),s:false}], "#333");
        }
        x += xLen(vhzSkal);
    }
    if (atSkal > 0) {
        ctx.fillStyle = "#ffeedd";
        ctx.fillRect(x, y2, xLen(atSkal), rowH);
        if (xLen(atSkal) >= 40) {
            drawParts(x, y2, xLen(atSkal), rowH,
                [{t:"HK2 * f",s:false},{t:"1",s:true},{t:" * f",s:false},{t:"2",s:true},{t:" = "+fmtDE(atSkal,1),s:false}], "#333");
        }
        x += xLen(atSkal);
    }


    // --- Zeile 3: Effektiv ---
    ctx.fillStyle = "#ddf5dd";
    ctx.fillRect(pad.l, y3, xLen(effektiv), rowH);
    ctx.fillStyle = "#333";
    ctx.font = "bold 14px sans-serif";
    ctx.textAlign = "left";
    if (xLen(effektiv) > 70) {
        ctx.fillText("Effektiv " + fmtDE(effektiv, 1) + " min", pad.l + 4, y3 + rowH / 2 + 5);
    } else {
        ctx.fillStyle = "#333";
        ctx.fillText(fmtDE(effektiv, 1) + " min", pad.l + xLen(effektiv) + 4, y3 + rowH / 2 + 5);
    }
    ctx.font = "14px sans-serif";
}

function labelSegment(ctx, x, y, w, h, text, color) {
    if (w < 20) return;
    ctx.fillStyle = color;
    ctx.textAlign = "center";
    var tx = x + w / 2;
    ctx.fillText(text, tx, y + h / 2 + 4);
}

// ---------------------------------------------------------------------------
// Event-Listener
// ---------------------------------------------------------------------------
var hkrDirty = false;
if (typeof hkrRaumHatEigeneGT === "undefined") { var hkrRaumHatEigeneGT = false; }

(function() {
    var ids = ["hkr-at", "hkr-grundtemp", "hkr-atg", "hkr-ist", "hkr-ziel", "hkr-gt", "hkr-vhz",
               "hkr-kv", "hkr-ka", "hkr-faktor1", "hkr-mindest", "hkr-kurve"];
    for (var i = 0; i < ids.length; i++) {
        var el = document.getElementById(ids[i]);
        if (el) {
            el.addEventListener("input",  function() { hkrDirty = true; berechnen(); });
            el.addEventListener("change", function() { hkrDirty = true; berechnen(); });
        }
    }

    // Grundtemperatur-Feld: hkr-gt nachfuehren, wenn kein raumindividueller Wert
    var grundtempEl = document.getElementById("hkr-grundtemp");
    if (grundtempEl) {
        grundtempEl.addEventListener("input", function() {
            if (!hkrRaumHatEigeneGT) {
                setFeld("hkr-gt", this.value);
            }
        });
    }

    var sel = document.getElementById("hkr-raum");
    if (sel) {
        sel.addEventListener("change", function() {
            if (hkrDirty) {
                if (!confirm("Die manuellen Eingaben werden durch die Raumwerte ersetzt. Fortfahren?")) {
                    // Auswahl rueckgaengig machen ist bei select nicht direkt moeglich,
                    // daher einfach nicht befuellen
                    return;
                }
            }
            raumWerteBefuellen(sel.value);
            hkrDirty = false;
            berechnen();
        });
    }

    // Erste Berechnung wenn alle Pflichtfelder vorbelegt sind
    berechnen();
})();

function raumWerteBefuellen(name) {
    if (typeof HKR_RAEUME === "undefined") return;
    for (var i = 0; i < HKR_RAEUME.length; i++) {
        var r = HKR_RAEUME[i];
        if (r.name === name) {
            hkrRaumHatEigeneGT = r.gt !== "";
            setFeld("hkr-ziel",    r.ziel);
            setFeld("hkr-gt",      hkrRaumHatEigeneGT ? r.gt : (typeof HKR_GT_GLOBAL !== "undefined" ? HKR_GT_GLOBAL : "10"));
            setFeld("hkr-ist",     r.ist !== "" ? r.ist : "18");
            setFeld("hkr-vhz",     r.vhz);
            setFeld("hkr-faktor1", r.f1);
            setFeld("hkr-mindest", r.mindest);
            return;
        }
    }
}

function setFeld(id, val) {
    var el = document.getElementById(id);
    if (el) el.value = val;
}

// ---------------------------------------------------------------------------
// Hilfsfunktion: VLZ_eff fuer einen Raum berechnen (mit f2, Ist-Temp aus Eingabefeld)
// ---------------------------------------------------------------------------
function berechneVLZ(raum, at, kv, kurve, ka, ist) {
    var f1      = Math.max(0.20, Math.min(5.0, parseFloat(raum.f1) || 1.0));
    var vhz     = parseFloat(raum.vhz) || 0;
    var mindest = parseFloat(raum.mindest) || 15;
    var gt      = parseFloat(raum.gt !== "" ? raum.gt : (typeof HKR_GT_GLOBAL !== "undefined" ? HKR_GT_GLOBAL : "10")) || 10;
    var ziel    = parseFloat(raum.ziel) || 20;
    var atRoh   = linearInterpolate(at, kurve);

    var f2 = 1.0;
    if ((ziel - gt) !== 0) {
        var istClip = Math.min(ist, ziel);
        var mitte   = gt + (ziel - gt) / 2;
        if (ist < mitte) {
            f2 = 1.0 - ka * ((istClip - gt) / (ziel - gt));
        } else {
            f2 = (2.0 - ka) * (1.0 - ((istClip - gt) / (ziel - gt)));
        }
    }

    var vhzAnteil = (vhz + kv) * f2;
    var atAnteil  = f1 * f2 * atRoh;
    var gesamt    = vhzAnteil + atAnteil;
    return { effektiv: Math.max(gesamt, mindest), gesamt: gesamt,
             vhzAnteil: vhzAnteil, atAnteil: atAnteil, mindest: mindest };
}

// ---------------------------------------------------------------------------
// Canvas: Raumvergleich
// ---------------------------------------------------------------------------
function zeichneVergleich(at, kv, kurve, ka, ist, aktiverRaum) {
    var canvas = document.getElementById("hkr-canvas-vergleich");
    if (!canvas || !canvas.getContext) return;
    if (typeof HKR_RAEUME === "undefined" || HKR_RAEUME.length === 0) return;

    // Ergebnisse berechnen und absteigend sortieren
    var ergebnisse = [];
    for (var i = 0; i < HKR_RAEUME.length; i++) {
        var r = HKR_RAEUME[i];
        var vlz = berechneVLZ(r, at, kv, kurve, ka, ist);
        var label = r.name.replace(/^HKG-Raum-/, "");
        ergebnisse.push({ label: label, name: r.name, vlz: vlz });
    }
    ergebnisse.sort(function(a, b) { return b.vlz.effektiv - a.vlz.effektiv; });

    var dpr  = window.devicePixelRatio || 1;
    var cssW  = 1146;
    var rowH  = 28;
    var padL  = 160, padR = 60, padT = 10, padB = 20;
    var cssH  = padT + ergebnisse.length * rowH + padB;
    canvas.width  = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
    canvas.style.width  = cssW + "px";
    canvas.style.height = cssH + "px";
    var ctx = canvas.getContext("2d");
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, cssW, cssH);

    var cw      = cssW - padL - padR;
    var maxVal  = ergebnisse[0].vlz.effektiv;
    if (maxVal <= 0) return;

    function xLen(v) { return Math.max(0, (v / maxVal) * cw); }

    for (var j = 0; j < ergebnisse.length; j++) {
        var e      = ergebnisse[j];
        var vlz    = e.vlz;
        var y      = padT + j * rowH;
        var barY   = y + 4;
        var barH   = rowH - 8;
        var aktiv  = (e.name === aktiverRaum);
        var greift = (vlz.gesamt < vlz.mindest);

        // Raumname
        ctx.fillStyle = aktiv ? "#000" : "#444";
        ctx.font      = aktiv ? "bold 12px sans-serif" : "12px sans-serif";
        ctx.textAlign = "right";
        ctx.textBaseline = "middle";
        ctx.fillText(e.label, padL - 6, y + rowH / 2);

        // VHZ-Anteil blau
        ctx.fillStyle = "#2980b9";
        ctx.fillRect(padL, barY, xLen(vlz.vhzAnteil), barH);
        // AT-Anteil orange
        ctx.fillStyle = "#e67e22";
        ctx.fillRect(padL + xLen(vlz.vhzAnteil), barY, xLen(vlz.atAnteil), barH);
        // Mindest-Aufschlag rot (nur wenn Mindest greift)
        if (greift) {
            var aufschlag = vlz.mindest - vlz.gesamt;
            ctx.fillStyle = "#c0392b";
            ctx.fillRect(padL + xLen(vlz.vhzAnteil) + xLen(vlz.atAnteil), barY, xLen(aufschlag), barH);
        }

        // Aktiven Raum umranden
        if (aktiv) {
            ctx.strokeStyle = "#333";
            ctx.lineWidth = 2;
            ctx.strokeRect(padL, barY, xLen(vlz.effektiv), barH);
        }

        // Minutenwert rechts
        ctx.fillStyle = "#333";
        ctx.font = "11px sans-serif";
        ctx.textAlign = "left";
        ctx.fillText(fmtDE(vlz.effektiv, 0) + " min", padL + xLen(vlz.effektiv) + 4, y + rowH / 2);
    }
}

// ---------------------------------------------------------------------------
// Canvas: Temperaturverlauf
// ---------------------------------------------------------------------------
function zeichneVerlauf(gt, ziel, ist, ka, vlzEff) {
    var canvas = document.getElementById("hkr-canvas-verlauf");
    if (!canvas || !canvas.getContext) return;
    var dpr  = window.devicePixelRatio || 1;
    var avail = canvas.parentElement ? canvas.parentElement.clientWidth - 24 : 0;
    var cssW  = avail > 200 ? avail : canvas.width;
    var cssH = Math.round(cssW * 0.28);
    canvas.width  = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
    canvas.style.width  = cssW + "px";
    canvas.style.height = cssH + "px";
    var ctx = canvas.getContext("2d");
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, cssW, cssH);
    var pad = {l: 50, r: 20, t: 15, b: 35};
    var cw = cssW - pad.l - pad.r;
    var ch = cssH - pad.t - pad.b;
    var f2Mitte = 1.0 - ka * 0.5;
    function f2ZuTemp(f2val) {
        if (ziel === gt) return gt;
        var anteil;
        if (f2val >= f2Mitte) { anteil = (1.0 - f2val) / ka; }
        else { anteil = 1.0 - f2val / (2.0 - ka); }
        return gt + anteil * (ziel - gt);
    }
    var tMin = Math.min(gt, ist) - 0.5;
    var tMax = ziel + 0.5;
    function xPos(t_min) { return pad.l + (t_min / vlzEff) * cw; }
    function yPos(temp)  { return pad.t + (1 - (temp - tMin) / (tMax - tMin)) * ch; }
    ctx.fillStyle = "#f8f8f8";
    ctx.fillRect(pad.l, pad.t, cw, ch);
    var tStep = (tMax - tMin) > 8 ? 2 : 1;
    var tStart = Math.ceil(tMin / tStep) * tStep;
    ctx.fillStyle = "#555"; ctx.font = "11px sans-serif"; ctx.textAlign = "right";
    for (var tg = tStart; tg <= tMax; tg += tStep) {
        var yp = yPos(tg);
        ctx.strokeStyle = "#ddd"; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(pad.l, yp); ctx.lineTo(pad.l + cw, yp); ctx.stroke();
        ctx.fillText(fmtDE(tg, 0) + "\u00b0", pad.l - 4, yp + 4);
    }
    ctx.textAlign = "center";
    var xStepMin = vlzEff > 120 ? 30 : vlzEff > 60 ? 15 : 10;
    for (var xm = 0; xm <= vlzEff; xm += xStepMin) {
        var xp = xPos(xm);
        ctx.strokeStyle = "#ddd"; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(xp, pad.t); ctx.lineTo(xp, pad.t + ch); ctx.stroke();
        ctx.fillText(fmtDE(xm, 0), xp, pad.t + ch + 14);
    }
    ctx.strokeStyle = "#888"; ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(pad.l, pad.t); ctx.lineTo(pad.l, pad.t + ch);
    ctx.lineTo(pad.l + cw, pad.t + ch); ctx.stroke();
    ctx.strokeStyle = "#aaa"; ctx.lineWidth = 1; ctx.setLineDash([4, 3]);
    ctx.beginPath(); ctx.moveTo(pad.l, yPos(ziel)); ctx.lineTo(pad.l + cw, yPos(ziel)); ctx.stroke();
    ctx.strokeStyle = "#88b"; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(pad.l, yPos(gt)); ctx.lineTo(pad.l + cw, yPos(gt)); ctx.stroke();
    ctx.setLineDash([]);
    ctx.strokeStyle = "#cc2200"; ctx.lineWidth = 2;
    ctx.beginPath();
    for (var s = 0; s <= 200; s++) {
        var f2val = 1.0 - (s / 200);
        var temp = f2ZuTemp(f2val);
        var xp2 = xPos((s / 200) * vlzEff);
        var yp2 = yPos(temp);
        if (s === 0) ctx.moveTo(xp2, yp2); else ctx.lineTo(xp2, yp2);
    }
    ctx.stroke();
    if (ist > gt && ist < ziel && vlzEff > 0) {
        var istClip = Math.min(ist, ziel);
        var mitte = gt + (ziel - gt) / 2;
        var f2ist;
        if (ist < mitte) { f2ist = 1.0 - ka * ((istClip - gt) / (ziel - gt)); }
        else { f2ist = (2.0 - ka) * (1.0 - ((istClip - gt) / (ziel - gt))); }
        var tIst = (1.0 - f2ist) * vlzEff;
        var xIst = xPos(tIst); var yIst = yPos(ist);
        ctx.fillStyle = "#cc2200";
        ctx.beginPath(); ctx.arc(xIst, yIst, 5, 0, 2 * Math.PI); ctx.fill();
        ctx.fillStyle = "#333"; ctx.font = "bold 11px sans-serif"; ctx.textAlign = "right";
        ctx.fillText("T_ist = " + fmtDE(ist, 1) + "\u00b0C", xIst - 8, yIst - 8);
    }
    ctx.fillStyle = "#555"; ctx.font = "11px sans-serif"; ctx.textAlign = "center";
    ctx.fillText("Minuten vor Termin", pad.l + cw / 2, cssH - 2);
    ctx.save();
    ctx.translate(12, pad.t + ch / 2); ctx.rotate(-Math.PI / 2);
    ctx.fillText("Temperatur (\u00b0C)", 0, 0);
    ctx.restore();
}
