#!/bin/bash

# 1. Nettoyage
rm -rf lab-idor

echo "--- DÉPLOIEMENT DU LAB 2 : IDOR ---"

# 2. Création du dossier
mkdir lab-idor
cd lab-idor

# [cite_start]3. Création du fichier index.php [cite: 17, 21]
cat <<EOF > index.php
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Intranet BankCorp</title>
    <style>
        body { font-family: sans-serif; background-color: #34495e; color: white; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .card { background: #ecf0f1; color: #2c3e50; padding: 40px; border-radius: 8px; width: 400px; box-shadow: 0 10px 20px rgba(0,0,0,0.3); }
        h1 { color: #e74c3c; border-bottom: 2px solid #bdc3c7; padding-bottom: 10px; }
        .info { margin: 15px 0; font-size: 1.2em; }
        .label { font-weight: bold; color: #7f8c8d; font-size: 0.8em; }
    </style>
</head>
<body>
<?php
\$users = [
    1001 => ["nom" => "Michel (Stagiaire)", "salaire" => "0 €", "note" => "Doit apprendre à faire le café."],
    1002 => ["nom" => "Sophie (Comptable)", "salaire" => "2500 €", "note" => "RAS."],
    1 => ["nom" => "THE BOSS (PDG)", "salaire" => "999.999 €", "note" => "FLAG{IDOR_Is_Easy_Peasy}"]
[cite_start]]; [cite: 38, 41, 48]
\$id = isset(\$_GET['id']) ? [cite_start]\$_GET['id'] : 1001; [cite: 51, 53]
\$profil = isset(\$users[\$id]) ? [cite_start]\$users[\$id] : null; [cite: 56]
?>
    <div class="card">
        <?php if (\$profil): ?>
            <h1>Fiche Employé #<?php echo htmlspecialchars(\$id); ?></h1>
            <div class="info"><div class="label">Nom:</div> <?php echo \$profil['nom']; ?></div>
            <div class="info"><div class="label">Notes RH:</div> <?php echo \$profil['note']; [cite_start]?></div> [cite: 60, 61, 62]
        <?php else: ?>
            [cite_start]<h1>Erreur</h1><p>Employé introuvable.</p> [cite: 64, 65]
        <?php endif; ?>
    </div>
</body>
</html>
EOF

# [cite_start]4. Création du Dockerfile [cite: 71, 74]
cat <<EOF > Dockerfile
FROM php:7.4-apache
COPY index.php /var/www/html/
EXPOSE 80
EOF

# 5. Lancement avec SUDO
[cite_start]sudo docker build -t lab-idor . [cite: 83]
[cite_start]sudo docker run -d -p 8082:80 lab-idor [cite: 86]

echo "--------------------------------------"
echo "TERMINÉ ! Accès : http://localhost:8082"
