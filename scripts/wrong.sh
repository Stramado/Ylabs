#!/bin/bash

# Ce script à pour objectif de créer un lab pour apprendre la cybersécurité
# La faille de ce lab est : problème de privilèges sur un exécutable (injection de commande)
# Ports ouverts : 22 (ssh) -> mdp donné
# Utilisateur : nick:Nick1234!
# Fichier compromis : /var/lib/finder : mod 4755

# Besoin des permissions root
if [[ $UID -ne 0 ]]; then
        echo "Les permissions root sont nécessaires pour exécuter ce script"
        exit 2
fi

apt install gcc -y

# Création de l'utilisateur
useradd nick
echo "nick:Nick1234!" | chpasswd
mkdir /home/nick
chown nick:nick /home/nick
chsh -s /bin/bash nick

# Création d'un fichier qui compilé, contiendra une injection de commande
echo "
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#define MAX_INPUT 4096

int main() {

        setuid(0);
        setgid(0);

        char value[MAX_INPUT];
        const char *command = \"/usr/bin/find / -wholename '\";
        const char *dev_null = \"' 2>/dev/null\";

        printf(\"Entrez le fichier que vous voulez chercher dans le système : \");
        if (fgets(value, sizeof(value), stdin) == NULL) {
                printf(\"Erreur de lecture\");
                return 1;
        }

        value[strcspn(value, \"\n\")] = '\0';

        char *result = malloc(strlen(value) + strlen(command) + strlen(dev_null) + 1);

        strcpy(result, command);
        strcat(result, value);
        strcat(result, dev_null);

        system(result);

        free(result);
        return 0;
}
" > /root/finder.c

gcc /root/finder.c -o /var/lib/finder

# Ajout des mauvaises permissions sur ce binaire
chown root:root /var/lib/finder
chmod 4755 /var/lib/finder

# Création du flag
echo "{Bravo_Tu_As_Trouve_Le_Flag_Jpa25vbhWjuf}" > /root/flag.txt
chmod 400 /root/flag.txt

# Lien des fichiers .bash_history vers /dev/null
ln -sf /dev/null .bash_history