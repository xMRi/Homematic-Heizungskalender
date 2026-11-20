# Remote-Zugriff

Ein Remote-Zugriff ermöglicht es, das Homematic-System auch von unterwegs zu erreichen und zu bedienen. Das ist praktisch, wenn Einstellungen angepasst oder Störungen geprüft werden müssen, während man nicht zu Hause ist. So lassen sich Geräte und Automatisierungen aus der Ferne pflegen, ohne vor Ort sein zu müssen.

## Remote-Zugriff mit der `HeizkalenderInstallation.exe`

Für den Fernzugriff auf die Homematic-Zentrale können verschiedene VPN-basierte Lösungen eingesetzt werden, zum Beispiel WireGuard oder Tailscale für den direkten Netzwerkzugriff. CloudMatic Connect bietet einen herstellerspezifischen Fernzugriff auf die CCU.

Letztlich benötigt die `HeizkalenderInstallation.exe` Zugriff auf Port 8181, um Skripte ausführen zu können.

Die einfachsten Zugriffsmöglichkeiten ohne detailierte Netzwerkkenntnisse bieten **CloudMatic** und **Tailscale**.

### CloudMatic

Der externe Zugriff auf die CCU mit dem Installationsprogramm kann über CloudMatic erfolgen. Dabei wird entweder eine verschlüsselte HTTPS-Verbindung über Port 44381 oder eine unverschlüsselte Verbindung über Port 8181 verwendet. Wir empfehlen, nur verschlüsselte Verbindungen zu nutzen.

Eine Anleitung zur Einrichtung des CloudMatic-Fernzugangs findet sich auf der Website von [CloudMatic/easy smarthome](https://docs.easy-smarthome.de/CloudMatic/Connect/Fernzugriff/?utm_source=chatgpt.com).

CloudMatic ist ein kostenpflichtiger Dienst. Für den Fernzugriff ist mindestens das Paket *CloudMatic Connect* erforderlich. In vielen Installationen nutzen wir *CloudMatic Complete*, weil es neben dem Fernzugriff auch eigene Diagramme, Ansichten und Darstellungen der CCU ermöglicht.

#### Wie erfolgt der Zugriff?

Der Zugriff erfolgt über eine eigene Webadresse, die CloudMatic zur Verfügung stellt.

Über eine zweite Adresse lässt sich eine Webseite zur Steuerung oder zur Anzeige von Diagrammen aufrufen.

**Pro**

- Direkte Integration in das Homematic-System
- Eigene Benutzer- und Zugriffssteuerung
- Einfache Konfiguration ohne aufwendige Einrichtung eines eigenen VPN-Zugangs
- Websteuerungen für eigene Bedienoberflächen und Funktionen
- Selbsterstellbare Diagramme zur übersichtlichen Darstellung von Messwerten und Verläufen
- Diagramme und Websteuerungen sind auch von außerhalb des eigenen Netzwerks erreichbar

**Contra**

- Laufende Kosten für den Dienst
- Abhängigkeit von CloudMatic und dessen Verfügbarkeit
- Die Einrichtung und Pflege eigener Diagramme und Websteuerungen erfordern Zeit und Einarbeitung
- Der Funktionsumfang hängt von der eingesetzten Homematic-Zentrale und den verfügbaren CloudMatic-Funktionen ab
- Nur bei Verwendung von Port 44381 (Option „Zugriff über CloudMatic“) erfolgt die Kommunikation verschlüsselt. Ein Zugriff über Port 8181 ist ebenfalls möglich, die Kommunikation ist dann jedoch unverschlüsselt.

### WireGuard

WireGuard ist ein VPN-Verfahren, mit dem sich Geräte unterwegs sicher mit dem Heimnetzwerk verbinden lassen. Bei einer passenden FRITZ!Box kann der Fernzugriff direkt über die Router-Einstellungen eingerichtet werden. Danach ist die Homematic-Zentrale so erreichbar, als wäre man zu Hause im eigenen Netzwerk.

Mit einer modernen FRITZ!Box ab FRITZ!OS 7.50 lässt sich dieser Zugriff einfach über WireGuard einrichten.

Auf der Website von ELV findet sich eine [Anleitung](https://ch.elv.com/elvwissen/elvprojekte/sicherheit/fernzugriff-auf-die-CCU-webui-und-hcu-web-per-wireguard-fritzbox/) zur Einrichtung von WireGuard und zum Zugriff auf eine CCU. Auch ein passendes [Erklärvideo](https://www.youtube.com/watch?v=j7wpmiuKrxY) ist auf YouTube verfügbar.

#### Wie erfolgt der Zugriff?

Der Zugriff erfolgt direkt über die IP-Adresse der CCU. Dabei müssen das Zielnetzwerk und das Netzwerk, aus dem zugegriffen wird, unterschiedliche IP-Adressbereiche verwenden.

Die Kommunikation ist vollständig verschlüsselt.

**Pro**

- Direkter Zugriff auf die Homematic-Zentrale und andere Geräte im Heimnetzwerk
- Keine zusätzliche Cloud für den Fernzugriff erforderlich
- WireGuard ist in neueren FRITZ!Box-Modellen integriert und lässt sich dort vergleichsweise einfach einrichten
- Die Verbindung kann auch für weitere Geräte und Dienste im Heimnetz genutzt werden

**Contra**

- Benötigt eine FRITZ!Box mit WireGuard-Unterstützung
- Die Einrichtung kann schwierig sein und setzt Netzwerkkenntnisse voraus
- Die VPN-Verbindung muss auf jedem verwendeten Smartphone oder Computer eingerichtet werden
- Der Zugriff hängt von der Internetverbindung zu Hause und der Verfügbarkeit des Routers ab
- WireGuard bietet keine eigenen Homematic-Diagramme oder Websteuerungen
- Die IP-Adressbereiche des Heimnetzes und des Zielnetzes müssen sich unterscheiden

### Tailscale (nur OpenCCU)

[Tailscale](https://www.tailscale.com) ist ein VPN-Dienst auf Basis von WireGuard, der direkt in OpenCCU integriert ist. Nach der Aktivierung von Tailscale in den Netzwerkeinstellungen der OpenCCU und der Installation des Tailscale-Clients auf einem Windows-PC kann von diesem PC aus über das Internet direkt auf OpenCCU zugegriffen werden.

#### Wie erfolgt der Zugriff?

Der Zugriff erfolgt direkt über eine IP-Adresse oder Webadresse, die Tailscale für das jeweilige Gerät bereitstellt. Dabei spielt es keine Rolle, wie die IP-Adressbereiche des Zielnetzes und des zugreifenden Netzes konfiguriert sind.

Die Kommunikation ist vollständig verschlüsselt.

**Pro**

- Tailscale ist direkt in OpenCCU integriert und lässt sich über die WebUI aktivieren
- Nach der Anmeldung mit einem Tailscale-Konto wird OpenCCU dem eigenen privaten Netzwerk hinzugefügt
- Tailscale bietet einen kostenlosen Tarif für den privaten Gebrauch
- Die Verbindung wird ohne Portweiterleitung am Router eingerichtet
- Der Zugriff auf die OpenCCU-WebUI ist von unterwegs möglich
- Funktioniert unabhängig von den IP-Adressbereichen des Heimnetzes und des Netzes, aus dem zugegriffen wird

**Contra**

- Die integrierte Tailscale-Funktion ist nur mit OpenCCU verfügbar
- Für die Einrichtung wird ein Tailscale-Konto benötigt
- Auch die Geräte, von denen aus zugegriffen werden soll, müssen in das Tailscale-Netzwerk eingebunden werden
- Tailscale ist ein zusätzlicher Dienst, von dessen Verfügbarkeit und Kontozugang der Fernzugriff abhängt
- Im Vergleich zu CloudMatic bietet Tailscale keine eigenen Homematic-Diagramme oder Websteuerungen

OpenCCU beschreibt den integrierten Client und die Einrichtung in der WebUI in der [Dokumentation zur WebUI](https://github-wiki-see.page/m/openccu/openccu/wiki/WebUI-Benutzung).

### Andere VPN-Dienste

Neben WireGuard und Tailscale gibt es weitere VPN-Lösungen, zum Beispiel die VPN-Funktion eines Routers oder einen selbst eingerichteten VPN-Server. Sie verbinden das Gerät unterwegs mit dem Heimnetzwerk und ermöglichen so den Zugriff auf die CCU, als wäre man zu Hause.

Sofern die VPN-Verbindung den Zugriff auf Port 8181 der CCU ermöglicht, kann auch die `HeizkalenderInstallation.exe` verwendet werden. Die Einrichtung und Verwaltung unterscheiden sich je nach VPN-Lösung. Meist sind dafür passende Router- oder Servereinstellungen sowie grundlegende Netzwerkkenntnisse erforderlich.
