#!/bin/bash

# ==========================================
# Gestionnaire du Lab : Serveur SSH Faible
# Usage : sudo ./lab_manager.sh [install|clean]
# ==========================================

# --- CONFIGURATION ---
USER_NAME="marvin"
USER_PASS="sunshine"
FLAG_CONTENT="FLAG{ssh_access_weak_password}"
WEB_ROOT="/var/www/html"
SSH_CONFIG="/etc/ssh/sshd_config"

# Verification des droits root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Erreur : Ce script doit etre lance avec sudo."
  exit 1
fi

# ==========================================
# FONCTION : INSTALLATION
# ==========================================
function install_lab() {
    echo "[*] Demarrage de l'installation..."

    # 1. Installation des paquets
    echo "[*] Installation/Mise a jour de Apache2 et SSH..."
    apt-get update -q
    apt-get install -y apache2 openssh-server -q

    # 2. Configuration SSH
    echo "[*] Configuration de SSH..."
    
    # Sauvegarde de la config d'origine
    if [ ! -f "${SSH_CONFIG}.bak" ]; then
        cp $SSH_CONFIG "${SSH_CONFIG}.bak"
        echo "    [+] Sauvegarde de la config SSH originale effectuee."
    fi

    # Modification pour autoriser les mots de passe
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' $SSH_CONFIG
    
    # Desactivation du root login par securite
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG

    # --- OPTIMISATION POUR LE BRUTEFORCE (HYDRA) ---
    # Ces lignes empechent le serveur de bloquer l'attaque si elle est trop rapide
    echo "" >> $SSH_CONFIG
    echo "# Configuration pour le Lab (autoriser bruteforce)" >> $SSH_CONFIG
    echo "MaxAuthTries 100" >> $SSH_CONFIG
    echo "MaxStartups 100" >> $SSH_CONFIG
    echo "    [+] SSH configure pour tolerer les attaques rapides."
    # -----------------------------------------------

    # Redemarrage SSH
    systemctl restart ssh
    echo "    [+] Service SSH redemarre."

    # 3. Configuration Web
    echo "[*] Mise en place du site web..."
    rm -f $WEB_ROOT/index.html
    
    # Page d'accueil
    echo "<h1>Bienvenue sur le serveur de test</h1><p>Acces restreint.</p>" > $WEB_ROOT/index.html
    
    # Robots.txt
    echo -e "User-agent: *\nDisallow: /admin_backup/\nDisallow: /tools/" > $WEB_ROOT/robots.txt
    
    # Dossier secret et Indice
    mkdir -p $WEB_ROOT/admin_backup
    echo "Ne pas oublier : l'utilisateur par defaut pour le SSH est $USER_NAME" > $WEB_ROOT/admin_backup/backup_admin_notes.txt
    
    # --- GENERATION DE LA WORDLIST ---
    echo "[*] Generation de la wordlist pour l'etudiant..."
    mkdir -p $WEB_ROOT/tools
    WORDLIST="$WEB_ROOT/tools/wordlist.txt"
    
    # Debut de la liste
    cat <<EOF > $WORDLIST
123456
password
admin
welcome
football
EOF
    # Remplissage
    for i in {6..289}; do echo "pass$i" >> $WORDLIST; done
    
    # Mot de passe cible (cache vers la fin)
    echo "$USER_PASS" >> $WORDLIST
    
    # Fin de la liste
    for i in {291..300}; do echo "admin$i" >> $WORDLIST; done

    # Permissions Web
    chown -R www-data:www-data $WEB_ROOT
    chmod -R 755 $WEB_ROOT

    # 4. Creation de l'utilisateur et Flag
    echo "[*] Creation de l'utilisateur cible ($USER_NAME)..."
    
    if id "$USER_NAME" &>/dev/null; then
        echo "    [!] L'utilisateur existe deja, mise a jour du mot de passe."
    else
        useradd -m -s /bin/bash $USER_NAME
    fi

    # Definition du mot de passe
    echo "$USER_NAME:$USER_PASS" | chpasswd
    
    # Creation du flag
    echo "$FLAG_CONTENT" > /home/$USER_NAME/flag.txt
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/flag.txt
    chmod 600 /home/$USER_NAME/flag.txt

    echo "=========================================="
    echo "[+] INSTALLATION TERMINEE."
    echo "IP de la machine : $(hostname -I | cut -d' ' -f1)"
    echo "=========================================="
}

# ==========================================
# FONCTION : NETTOYAGE
# ==========================================
function clean_lab() {
    echo "[*] Demarrage du nettoyage..."

    # 1. Suppression Utilisateur
    if id "$USER_NAME" &>/dev/null; then
        userdel -r $USER_NAME 2>/dev/null
        echo "    [-] Utilisateur $USER_NAME supprime."
    else
        echo "    [!] Utilisateur introuvable."
    fi

    # 2. Suppression Web
    rm -f $WEB_ROOT/robots.txt
    rm -rf $WEB_ROOT/admin_backup
    rm -rf $WEB_ROOT/tools
    echo "<h1>It works!</h1>" > $WEB_ROOT/index.html
    echo "    [-] Fichiers du lab supprimes du serveur web."

    # 3. Restauration SSH
    if [ -f "${SSH_CONFIG}.bak" ]; then
        cp "${SSH_CONFIG}.bak" $SSH_CONFIG
        systemctl restart ssh
        rm "${SSH_CONFIG}.bak"
        echo "    [-] Configuration SSH d'origine restauree."
    else
        echo "    [!] Pas de backup SSH trouve, configuration actuelle conservee."
    fi

    echo "=========================================="
    echo "[+] NETTOYAGE TERMINE."
    echo "=========================================="
}

# ==========================================
# LOGIQUE PRINCIPALE
# ==========================================
case "$1" in
    install)
        install_lab
        ;;
    clean)
        clean_lab
        ;;
    *)
        echo "Usage: sudo $0 {install|clean}"
        exit 1
        ;;
esac