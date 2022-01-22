# Morgengrauen Script Plugin fuer Blightmud

Blightmud ist ein neuerer Mudclient, welcher eine alternative zu TF darstellen soll, zumindest so die Aussage vom Entwickler. Dieses Plugin enthaelt erste kleine Gehversuche um Blightmud fuer das Morgengrauen anzupassen.

## Installation
1. Installiere Blightmud wie [hier](https://github.com/Blightmud/Blightmud) beschrieben
   
2. In Blightmud installiere das Plugin wie folgt:
    ```
    /add_plugin https://github.com/cmetz/mg-blightmud
    ```

## Erste Schritte
1. Verbindung mit dem Morgengrauen
   ```
   /connect mg.mud.de 23 
   ```
   alternativ mit TLS, erfordert ggf. ein entsprechendes Root Zertifikat, mehr dazu [hier](https://mg.mud.de/download/stunnel.shtml)
   ```
   /connect mg.mud.de 4712 true
   ```

2. Login:
   Das Plugin zeigt Eingabeaufforderungen (Prompts) vom Morgengrauen, wie z.B. das Login/Passwort in der unteren Statuszeile an und nicht in dem Hauptausgabe Fenster.

3. Trigger, Aliase, usw werden aktuell in Blightmud mit LUA-Scripten umgesetzt. Mehr dazu erfaehrst du in der Blightmud Hilfe (/help).
