#!/bin/bash

# Nom du projet et du dossier
DIR_NAME="lab-cyber"
IMAGE_NAME="lab-cyber-lvl2"
CONTAINER_NAME="cible-cyber"

echo "[+] Création du dossier $DIR_NAME..."
mkdir -p "$DIR_NAME"
cd "$DIR_NAME" || exit

# 1. Création du Dockerfile [cite: 8, 10]
echo "[+] Création du Dockerfile..."
cat << 'EOF' > Dockerfile
FROM ubuntu:20.04

# Éviter les questions interactives lors de l'installation [cite: 12, 13]
ENV DEBIAN_FRONTEND=noninteractive

# 1. Installation des paquets nécessaires (Apache, PHP, Netcat, Nano) [cite: 14-20]
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    libapache2-mod-php \
    netcat \
    nano \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuration du site Web vulnérable [cite: 22-26]
RUN rm /var/www/html/index.html
COPY index.php /var/www/html/index.php
COPY upload.php /var/www/html/upload.php
RUN mkdir /var/www/html/uploads && chmod 777 /var/www/html/uploads

# 3. CRÉATION DES FLAGS [cite: 27]
# Flag 1: User [cite: 28, 29]
RUN echo "FLAG{Bienvenue_dans_le_shell}" > /var/www/user_flag.txt
# Flag 2: Root [cite: 30]
RUN echo "FLAG{Tu_es_le_maitre_du_systeme}" > /root/root_flag.txt

# 4. CRÉATION DE LA VULNERABILITÉ ROOT (PrivEsc) [cite: 31, 33]
# SUID bit sur find
RUN chmod u+s /usr/bin/find

# 5. Configuration finale [cite: 34-36]
EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EOF

# 2. Création de index.php [cite: 37-51]
echo "[+] Création de index.php..."
cat << 'EOF' > index.php
<!DOCTYPE html>
<html>
<head>
<title>TechCorp - Maintenance</title>
<style>body {font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f4f4f4; }
</style>
</head>
<body>
<h1>TechCorp Intranet</h1>
<p>Ce serveur est en maintenance.</p>
</body>
</html>
EOF

# 3. Création de upload.php [cite: 52-75]
# Note : Syntaxe corrigée par rapport au PDF pour assurer le fonctionnement PHP
echo "[+] Création de upload.php..."
cat << 'EOF' > upload.php
<!DOCTYPE html>
<html>
<body>
<h2>Outil de transfert de logs (Interne)</h2>
<form action="" method="post" enctype="multipart/form-data">
Selectionnez un fichier:
<input type="file" name="fileToUpload" id="fileToUpload">
<input type="submit" value="Envoyer" name="submit">
</form>
</body>
</html>
<?php
if(isset($_POST["submit"])) {
    $target_dir = "uploads/";
    $target_file = $target_dir . basename($_FILES["fileToUpload"]["name"]);
    
    // VULNERABILITÉ: Aucune vérification de l'extension (.php accepté)
    if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
        echo "<p>Le fichier a été téléversé avec succès</p>";
        echo "<p>Chemin: <a href='" . $target_file . "'>" . $target_file . "</a></p>";
    } else {
        echo "<p>Erreur lors du téléversement.</p>";
    }
}
?>
EOF

# 4. Construction et lancement [cite: 76-83]
echo "[+] Construction de l'image Docker ($IMAGE_NAME)..."
docker build -t $IMAGE_NAME .

echo "[+] Démarrage du conteneur ($CONTAINER_NAME)..."
# Arrêt de l'ancien conteneur s'il existe déjà pour éviter les conflits
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

docker run -d -p 8080:80 --name $CONTAINER_NAME $IMAGE_NAME

echo "---------------------------------------------------"
echo "[OK] Lab déployé avec succès !"
echo "Le site est accessible sur : http://localhost:8080"
echo "---------------------------------------------------"
