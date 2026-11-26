# Heizkurvenoptimierung mit KI

Mithilfe einer KI können die HK2-Heizkurve und die individuellen Vorheizparameter der Räume anhand der tatsächlich aufgezeichneten Heizvorgänge analysiert und schrittweise optimiert werden.

Das vorrangige Ziel ist es, die gewünschte Wohlfühltemperatur in einem Zeitfenster von 45 Minuten vor bis 15 Minuten nach Terminbeginn zu erreichen. Dabei sollen vorrangig die individuellen Raumparameter optimiert werden. Eine Anpassung der globalen HK2-Heizkurve erfolgt dann, wenn sich systematische, gleichartige Abweichungen bei mehreren Räumen feststellen lassen.

Bei allen Optimierungen gilt der Grundsatz: **Wohlfühlen vor Energiesparen.**

## Auswahl des KI-Anbieters

Die Definition der Heizkurvenoptimierung ist anbieterneutral formuliert. Für die Analyse können grundsätzlich auch die kostenlosen Angebote gängiger KI-Dienste wie ChatGPT, Claude oder Google Gemini verwendet werden. **Ein kostenpflichtiges Abonnement ist nicht zwingend erforderlich.**

Das verwendete KI-Modell muss in der Lage sein, die bereitgestellten Dokumente und Protokolldaten zu verarbeiten sowie die beschriebenen mathematischen Berechnungen und Auswertungen durchzuführen.

Je nach KI-Modell können sich die Qualität der Analyse und die Genauigkeit der Optimierungsvorschläge unterscheiden. Bei umfangreichen Protokolldaten können zudem die Nutzungslimits kostenloser Angebote erreicht werden.

## Vorgehensweise

Die Optimierung erfolgt in mehreren aufeinanderfolgenden Testläufen. Für jeden Testlauf werden die aktuellen Einstellungen des Heizkalenders dokumentiert und die damit erzeugten Heizkurvendaten ausgewertet.

Auf Grundlage dieser Daten erstellt die KI Vorschläge zur Anpassung der globalen HK2-Heizkurve und der individuellen Raumparameter. Nach der Übernahme der gewünschten Änderungen beginnt ein neuer Testlauf, mit dem die Auswirkungen der Änderungen überprüft werden können.

Durch die fortlaufende Dokumentation der Parameterstände und Auswertungszeiträume kann die KI die Ergebnisse der einzelnen Testläufe miteinander vergleichen und die Optimierung schrittweise fortsetzen.

### 1. Vorbereitung

Für die Optimierung stehen zwei Dokumente zur Verfügung:

- **[Definition der Heizkurvenoptimierung](heizkurven_optimierung_ki_definiton.md)**  
  Enthält die Berechnungsgrundlagen des Heizkalenders, die Auswertungsregeln, die Optimierungsziele und die Anweisungen für die KI.
- **[Eingabeformular](heizkurven_optimierung_ki_eingabeformular.md)**  
  Dient zur Dokumentation der globalen Einstellungen, der individuellen Raumparameter und der aufeinanderfolgenden Testläufe.

Die Definition ist installationsunabhängig und kann unverändert verwendet werden. Das Eingabeformular wird für die jeweilige Heizkalenderinstallation ausgefüllt und im Laufe der Optimierung fortgeschrieben.

Eine installationsbezogene Kopie des Eingabeformulars sollte lokal gespeichert werden.

Voraussetzung für die Optimierung ist eine **aktivierte Protokollierung der Heizkurvenkontrolle** (`HK-LoggingHeizkurvenkontrolle`) sowie die regelmäßige Sicherung der Protokolldaten auf einem USB-Stick.

### 2. Basisdaten ermitteln und Eingabeformular ausfüllen

Zur Ermittlung der aktuellen globalen Einstellungen und der individuellen Raumparameter steht ein spezielles Testskript zur Verfügung.

Das Skript befindet sich im Projektordner des Heizkalenders unter:

`Skripte\HK-Test-Skript-Heizkurvendaten.hsc`

Es kann auch direkt aus dem GitHub-Projekt heruntergeladen werden:

**[HK-Test-Skript-Heizkurvendaten.hsc](https://github.com/xMRi/Homematic-Heizungskalender/raw/refs/heads/main/Skripte/HK-Test-Skript-Heizkurvendaten.hsc)**

Zur Ermittlung der Basisdaten wie folgt vorgehen:

1. Das Skript mit einem Texteditor öffnen.
2. Falls bei der Installation ein Variablenprefix verwendet wird, dieses im variablen Bereich des Skripts bei `vrp` eintragen.
3. In der CCU-Weboberfläche unter **Programme und Verknüpfungen → Programme und Zentralenverknüpfungen** die Funktion **Skript testen** aufrufen.
4. Den vollständigen Skripttext in das Eingabefeld kopieren und ausführen.
5. Die ausgegebenen Daten in die entsprechenden Abschnitte des Eingabeformulars übernehmen.

Das Skript verändert keine Einstellungen des Heizkalenders und gibt keine Zugangsdaten aus.

Die Ausgabe des Skripts enthält zwei Bereiche:

- **Globale Parameter zur Heizkurvenoptimierung:**  
  Diese Systemvariablen werden unverändert in **[Abschnitt B – Globale Standardwerte](heizkurven_optimierung_ki_eingabeformular.md#b-globale-standardwerte)** des Eingabeformulars übernommen.
- **Raumparameter zur Heizkurvenoptimierung:**  
  Diese Raumvariablen werden unverändert in **[Abschnitt C](heizkurven_optimierung_ki_eingabeformular.md#c-raumparameter)** des Eingabeformulars übernommen.

Eine manuelle Aufschlüsselung oder Interpretation der Raumvariablen ist nicht erforderlich. Die Definition enthält die notwendigen Informationen, damit die KI die einzelnen Parameter selbstständig ermitteln kann.

Die übrigen Angaben in **[Abschnitt B](heizkurven_optimierung_ki_eingabeformular.md#b-globale-standardwerte)** des Eingabeformulars, beispielsweise die Skriptversion, das Installationsdatum und die Referenz-Wohlfühltemperatur der HK2-Kurve, müssen manuell ergänzt werden.

In **[Abschnitt D – Ergänzende Angaben](heizkurven_optimierung_ki_eingabeformular.md#d-erganzende-angaben)** des Eingabeformulars können ergänzende Angaben zu den Räumen und den Betriebsbedingungen hinterlegt werden. Dazu gehören beispielsweise:

- Fußbodenheizungen oder andere besonders träge Heizsysteme.
- Nachtabsenkungen und zeitliche Einschränkungen der Heizungsanlage.
- Besondere Temperaturquellen oder fehlende Raumtemperaturmessungen.
- Bauliche Besonderheiten und thermische Einflüsse benachbarter Räume.
- Einflüsse durch Sonneneinstrahlung, Lüftung oder häufig geöffnete Türen.
- Bekannte Einschränkungen der Heizleistung.
- Auffälligkeiten bei Thermostaten, Heizkörpern oder Temperatursensoren.
- Sonstige bekannte Einflüsse auf das Aufheizverhalten.

Diese Informationen helfen der KI, Auffälligkeiten richtig einzuordnen und geeignete Änderungsvorschläge zu erstellen. Die Angaben müssen nicht vollständig sein und können im Laufe der Optimierung ergänzt werden.

### 3. Ersten Testlauf durchführen

Den Heizkalender über einen geeigneten Zeitraum mit den im Eingabeformular dokumentierten und **unveränderten Parametern** betreiben.

Eine erste Auswertung kann bereits nach einer Woche erfolgen. Bei wenigen Heizvorgängen oder geringen Schwankungen der Außentemperatur sind allerdings nur vorläufige und entsprechend vorsichtige Korrekturen möglich.

Nach Abschluss des Testlaufs den Auswertungszeitraum in **[Abschnitt A – Auswertungszeitraum](heizkurven_optimierung_ki_eingabeformular.md#a-auswertungszeitraum)** des Eingabeformulars eintragen.

Es ist auch möglich, bereits vorhandene Daten aus der Heizkurvenkontrolle für den ersten Testlauf zu verwenden, sofern bekannt ist, mit welchen Parametern diese Daten erzeugt wurden.

### 4. Heizkurvendaten aus dem Addon ermitteln

Die benötigten Daten können über die Heizkurvenkontrolle des Heizkalender-Addons ermittelt werden.

Das Addon wird über die CCU-Weboberfläche unter **Einstellungen → Zusatzsoftware → Heizkalender → Einstellungen** aufgerufen.

In der Heizkurvenkontrolle sind folgende Einstellungen vorzunehmen:

| Filter | Einstellung |
|---|---|
| Zeitraum | Entsprechend dem Auswertungszeitraum, z. B. letzte 7 oder 30 Tage |
| Raum | Alle Räume |
| Ereignis | Alle Ereignisse |
| Raumtemperatur anzeigen | Aktivieren |

Anschließend auf **Anzeigen** klicken.

Die zusätzliche Anzeige der Raumtemperaturen ist besonders wichtig, da diese Messungen eine bessere Beurteilung des Aufheizverhaltens und des Temperaturverlaufs ermöglichen.

Die vollständige Ergebnistabelle **einschließlich der Spaltenüberschriften** markieren, in die Zwischenablage kopieren und mit einem Texteditor in einer Textdatei speichern.

Die dabei entstehenden tabulatorgetrennten Daten können direkt von der KI verarbeitet werden. Eine Umformatierung oder manuelle Aufbereitung der Daten ist nicht erforderlich.

Alternativ können die Daten auch im ursprünglichen Log-Format bereitgestellt werden.

Darauf achten, dass die bereitgestellten Daten den im Eingabeformular angegebenen Auswertungszeitraum abdecken. Da die Sicherung der Protokolldaten auf dem USB-Stick in regelmäßigen Abständen erfolgt, können die jüngsten Heizereignisse noch in der Anzeige fehlen.

Weitere Informationen finden sich im [Anwenderhandbuch des Heizkalender-Addons – Heizkurvenkontrolle](https://xmri.github.io/Homematic-Heizungskalender/addon/anwenderhandbuch/#heizkurvenkontrolle).

### 5. Analyse und Optimierung durch die KI

Der KI werden gemeinsam drei Dokumente bzw. Dateien übergeben:

- Die **[Definition der Heizkurvenoptimierung](heizkurven_optimierung_ki_definiton.md)**.
- Das **ausgefüllte Eingabeformular**.
- Die **Daten aus der Heizkurvenkontrolle**.

Die Dateien können bei den meisten KI-Anbietern direkt als Anhang einer Anfrage hinzugefügt werden.

Als Arbeitsauftrag an die KI genügt beispielsweise:

> Analysiere die Daten aus der Heizkurvenkontrolle anhand der beigefügten Definition und des Eingabeformulars. Erstelle konkrete Vorschläge zur Optimierung der HK2-Heizkurve und der individuellen Raumparameter.

Die KI soll anhand der Definition die bisherigen Heizvorgänge bewerten, Auffälligkeiten erkennen und begründete Änderungsvorschläge erstellen.

**Die vorgeschlagenen Änderungen sollten vor der Übernahme geprüft werden.** Insbesondere bei wenigen Messdaten sind größere Parameteränderungen zu vermeiden. Nicht jede von der KI vorgeschlagene Änderung muss umgesetzt werden.

Die Auswirkungen vorgeschlagener Parameteränderungen auf die berechneten Vorheizzeiten können zusätzlich mit dem Vorheizzeit-Rechner des Heizkalender-Addons überprüft werden.

### 6. Einen weiteren Testlauf durchführen

Nach der Auswertung und Übernahme der gewünschten Parameteränderungen beginnt ein neuer Testlauf.

1. Die gewünschten Parameteränderungen im Heizkalender vornehmen.
2. Im bestehenden Eingabeformular einen **neuen Testlauf mit fortlaufender Nummer** ergänzen.
3. Das Skript `HK-Test-Skript-Heizkurvendaten.hsc` erneut ausführen, wie unter [Basisdaten ermitteln und Eingabeformular ausfüllen](#2-basisdaten-ermitteln-und-eingabeformular-ausfullen) beschrieben.
4. Den vollständigen neuen Parametersatz in das Eingabeformular übernehmen, auch wenn nur einzelne Parameter geändert wurden.
5. Gegebenenfalls die ergänzenden Angaben aktualisieren.
6. Den Heizkalender erneut über einen geeigneten Zeitraum mit unveränderten Parametern betreiben.
7. Die neuen [Heizkurvendaten aus dem Addon ermitteln](#4-heizkurvendaten-aus-dem-addon-ermitteln) und den Auswertungszeitraum im Eingabeformular eintragen.
8. Der KI erneut die Definition, das fortgeschriebene Eingabeformular und die neuen Heizkurvendaten zur Auswertung übergeben.

**Die Angaben früherer Testläufe dürfen nicht überschrieben werden.** Nur so bleiben die jeweiligen Parameterstände und deren Auswirkungen nachvollziehbar.

Es empfiehlt sich, auch die Heizkurvendaten und Auswertungsergebnisse aller bisherigen Testläufe aufzubewahren und diese bei Bedarf erneut bereitzustellen.

Die weitere Optimierung kann innerhalb derselben KI-Unterhaltung erfolgen. Durch die vollständige Dokumentation der Testläufe ist es aber auch möglich, eine neue KI-Unterhaltung zu beginnen oder einen anderen KI-Anbieter zu verwenden. In diesem Fall sollten auch die Heizkurvendaten der bisherigen Testläufe bereitgestellt werden, sofern deren Ergebnisse in die weitere Analyse einfließen sollen.

### 7. Auswertungsintervalle

In der Anfangsphase der Optimierung empfiehlt sich eine **wöchentliche Auswertung**. Dadurch können größere Abweichungen frühzeitig erkannt und schrittweise korrigiert werden.

Mit zunehmender Qualität der Heizkurve und der individuellen Raumparameter können die Auswertungsintervalle verlängert werden, beispielsweise auf zwei bis vier Wochen.

Auch nach einer erfolgreichen Optimierung kann eine erneute Auswertung sinnvoll sein, insbesondere bei deutlich veränderten Außentemperaturen, beim Übergang in eine andere Jahreszeit oder nach Änderungen an der Heizungsanlage.

Die Optimierung ist ein schrittweiser Prozess. **Nicht bei jeder Auswertung müssen Parameter geändert werden.**