#!/bin/bash

# Configuration
WEB_ROOT="www"
UPLOAD_DIR="$WEB_ROOT/uploads"

echo "[*] Nettoyage et création du LAB..."
rm -rf "$WEB_ROOT"
mkdir -p "$UPLOAD_DIR"

# --- PAGE 1 : CONNEXION ---
# Note : Utilisation de 'EOF' avec des guillemets simples pour bloquer l'interprétation Bash
cat << 'EOF' > "$WEB_ROOT/index.php"
<?php
session_start();
if (!empty($_POST['username'])) {
    $_SESSION['user'] = htmlspecialchars($_POST['username']);
    header('Location: dashboard.php');
    exit();
}
?>
<!DOCTYPE html>
<html>
<head>
    <style>body{font-family:sans-serif;background:#f0f2f5;display:flex;justify-content:center;padding:50px;}.card{background:white;padding:30px;border-radius:10px;box-shadow:0 4px 10px rgba(0,0,0,0.1);width:350px;text-align:center;}input{width:100%;padding:10px;margin:10px 0;box-sizing:border-box;}</style>
    <title>Connexion</title>
</head>
<body>
    <div class="card">
        <h2>Intranet Entreprise</h2>
        <form method="POST">
            <input type="text" name="username" placeholder="Prénom de l'employé" required>
            <button type="submit" style="width:100%;padding:10px;background:#0062cc;color:white;border:none;border-radius:5px;cursor:pointer;">Entrer</button>
        </form>
    </div>
</body>
</html>
EOF

# --- PAGE 2 : DASHBOARD (UPLOAD VULNÉRABLE) ---
cat << 'EOF' > "$WEB_ROOT/dashboard.php"
<?php
$name = $_FILES['avatar']['name'];
// On récupère l'extension du fichier (ex: .php)
$extension = "." . pathinfo($name, PATHINFO_EXTENSION);

// On convertit en minuscules pour éviter que "FILE.PHP" contourne le filtre
switch (strtolower($extension)) {
    case '.pdf':
    case '.txt':
    case '.mp3':
    case '.mp4':
    case '.exe':
    case '.zip':
    case '.doc':
    case '.docx':
        // Si l'un de ces cas est vrai, on affiche l'erreur
        $msg = "<p style='color:red;'>Erreur : Le format $extension est interdit !</p>";
        break;

    default:
        // Si l'extension n'est pas dans la liste au-dessus, on autorise l'upload
        if (move_uploaded_file($_FILES['avatar']['tmp_name'], "uploads/" . $name)) {
            $msg = "<p style='color:green;'>Fichier chargé dans uploads/$name</p>";
        } else {
            $msg = "<p style='color:red;'>Erreur lors du transfert sur le serveur.</p>";
        }
        break;
}
?>
<!DOCTYPE html>
<html>
<head>
    <style>body{font-family:sans-serif;background:#f0f2f5;display:flex;justify-content:center;padding:50px;}.card{background:white;padding:30px;border-radius:10px;width:400px;text-align:center;}</style>
    <title>Dashboard</title>
</head>
<body>
    <div class="card">
        <h2>Bienvenue <?php echo $_SESSION['user']; ?></h2>
        <hr>
        <?php echo $msg; ?>
        <form method="POST" enctype="multipart/form-data">
            <p>Uploader votre photo :</p>
            <input type="file" name="avatar" required><br><br>
            <button type="submit" style="width:100%;padding:10px;background:#28a745;color:white;border:none;border-radius:5px;cursor:pointer;">Mettre à jour</button>
        </form>
        <br>
        <a href="index.php" style="font-size:0.8em;color:#666;">Déconnexion</a>
    </div>
</body>
</html>
EOF

# --- FLAG ET PERMISSIONS ---
# On place le flag deux dossiers au dessus du dossier uploads
pwd
echo "CTF{C_3ta1t_Vrm_P4S_tRes_S3cRIS3r}" > flag.txt
chmod -R 755 "$WEB_ROOT"
chmod 777 "$UPLOAD_DIR"

echo "[OK] Lab prêt
"
php -S 0.0.0.0:8000 -t www

