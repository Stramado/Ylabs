#!/bin/bash

# Couleurs pour le terminal
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # Pas de couleur

echo -e "${CYAN}--- DÉPLOIEMENT DU LAB DE SÉCURITÉ : PING DE LA MORT ---${NC}"

# 1. Mise à jour et installation de Docker
echo -e "${GREEN}[1/5] Vérification et installation de Docker...${NC}"
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker

# 2. Préparation du dossier
echo -e "${GREEN}[2/5] Création de l'espace de travail...${NC}"
mkdir -p lab-ping && cd lab-ping

# 3. Création de l'interface esthétique (index.php)
echo -e "${GREEN}[3/5] Génération du code PHP vulnérable...${NC}"
cat <<EOF > index.php
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Cyber-Audit : Outil de Diagnostic</title>
    <style>
        body { background-color: #0d1117; color: #00ff41; font-family: 'Courier New', monospace; display: flex; flex-direction: column; align-items: center; padding: 50px; }
        .container { background-color: #161b22; padding: 30px; border-radius: 10px; border: 1px solid #30363d; box-shadow: 0 0 20px rgba(0, 255, 65, 0.2); width: 80%; max-width: 800px; }
        h1 { border-bottom: 2px solid #00ff41; padding-bottom: 10px; }
        input[type="text"] { background: #0d1117; border: 1px solid #30363d; color: #00ff41; padding: 10px; width: 65%; border-radius: 5px; }
        input[type="submit"] { background: #00ff41; color: #0d1117; border: none; padding: 10px 20px; cursor: pointer; font-weight: bold; border-radius: 5px; }
        pre { background: #000; padding: 15px; border-radius: 5px; overflow-x: auto; color: #d1d5da; border-left: 3px solid #00ff41; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Diagnostic Réseau v2.0</h1>
        <form method="POST">
            <input type="text" name="ip" placeholder="Entrez une IP (ex: 8.8.8.8)" required>
            <input type="submit" value="LANCER LE TEST">
        </form>
        <?php if (isset($_POST['ip'])): ?>
            <pre><?php system("ping -c 3 " . $_POST['ip']); ?></pre>
        <?php endif; ?>
    </div>
</body>
</html>
EOF

# 4. Création du Dockerfile
echo -e "${GREEN}[4/5] Préparation de la recette Docker...${NC}"
cat <<EOF > Dockerfile
FROM php:7.4-apache
RUN apt-get update && apt-get install -y iputils-ping
COPY index.php /var/www/html/
RUN echo "BRAVO{C0mm4nd_Inj3ct10n_Success}" > /flag.txt
EXPOSE 80
EOF

# 5. Construction et Lancement
echo -e "${GREEN}[5/5] Construction et démarrage du conteneur...${NC}"
docker build -t lab-ping .
docker run -d -p 8080:80 lab-ping
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}SUCCÈS ! Le lab est accessible sur : http://localhost:8080${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"
