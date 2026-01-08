#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="${HOME}/lab-xss-intranova"
SITE_DIR="${LAB_ROOT}/site"
SENS_DIR="${SITE_DIR}/sensitive"

echo "📁 Création des dossiers..."
mkdir -p "${SENS_DIR}"

echo "🧾 Création des fichiers du lab dans: ${SITE_DIR}"

# -------------------------
# index.php (accueil public)
# -------------------------
cat > "${SITE_DIR}/index.php" <<'PHP'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>IntraNova · Support Center</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>

<header class="topbar">
  <div class="logo">IntraNova <span>· Support Center</span></div>
  <!-- Lien public : pas d'accès admin -->
  <a class="badge" href="admin_denied.php">INTRANET</a>
</header>

<main class="container">
  <h1>Ticket d’assistance</h1>
  <p class="subtitle">
    Les équipes publient ici leurs demandes.
    Le contenu est affiché tel quel pour préserver la mise en forme.
  </p>

  <section class="card">
    <form method="GET" autocomplete="off">
      <label>Message du ticket</label>
      <input type="text" name="msg" placeholder="Décrivez votre problème">
      <button type="submit">Envoyer</button>
    </form>

    <div class="render">
      <p class="hint">Rendu du commentaire :</p>
      <div class="output">
        <?php
          if (isset($_GET['msg'])) {
            echo $_GET['msg']; // VULNÉRABILITÉ XSS (volontaire pour le lab)
          } else {
            echo "<span class='empty'>Aucun message pour l’instant.</span>";
          }
        ?>
      </div>
    </div>
  </section>

  <!--
    TODO (interne) :
    Activer une redirection interne après validation sécurité.
    window.location.href = "/internal/preview";
  -->

</main>
</body>
</html>
PHP

# -------------------------
# admin_denied.php (page accès refusé)
# -------------------------
cat > "${SITE_DIR}/admin_denied.php" <<'PHP'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Accès restreint</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>

<header class="topbar">
  <div class="logo">IntraNova <span>· Accès restreint</span></div>
  <a class="badge" href="index.php">RETOUR</a>
</header>

<main class="container">
  <section class="card">
    <h1>Accès refusé</h1>

    <p class="subtitle">
      Vous ne disposez pas des autorisations nécessaires pour accéder
      à la session administrateur.
    </p>

    <p class="muted">
      Cette interface est réservée aux membres du service interne.
    </p>

    <p style="margin-top:18px;" class="muted">
      (Simulation : l’admin n’est pas exposé depuis le portail public.)
    </p>

    <p style="margin-top:20px;">
      <a href="index.php">← Retour au portail public</a>
    </p>
  </section>
</main>

</body>
</html>
PHP

# -------------------------
# admin.php (bloquée si accès direct)
# accès interne : admin.php?internal=1
# -------------------------
cat > "${SITE_DIR}/admin.php" <<'PHP'
<?php
// Simulation : l'interface admin n'est pas accessible depuis le portail public.
// On autorise uniquement si le contexte "interne" est présent.
if (!isset($_GET['internal']) || $_GET['internal'] !== '1') {
  header("Location: admin_denied.php");
  exit;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>IntraNova · Administration</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>

<header class="admin-topbar">
  <div class="admin-logo">IntraNova <span>Administration</span></div>
  <div class="admin-user">
    Connecté en tant que <strong>admin@intranova.local</strong>
  </div>
</header>

<div class="admin-layout">

  <aside class="admin-sidebar">
    <h3>Navigation</h3>
    <ul>
      <li class="active">📋 Tickets</li>
      <li>👥 Utilisateurs</li>
      <li>📊 Statistiques</li>
      <li>⚙️ Paramètres</li>
    </ul>
  </aside>

  <main class="admin-content">

    <h1>Tableau de bord</h1>
    <p class="admin-subtitle">
      Portail interne de gestion des tickets et contenus utilisateurs.
    </p>

    <section class="admin-card">
      <h2>Session active</h2>
      <ul class="admin-info">
        <li><strong>Rôle :</strong> Administrateur</li>
        <li><strong>Niveau :</strong> Accès interne</li>
        <li><strong>Dernière connexion :</strong> Aujourd’hui</li>
      </ul>

      <div class="admin-meta">
        <span class="muted">Outils :</span>
        <a class="stealth-link" href="grant_internal.php">Ressources internes</a>
      </div>

      <!--
        Note interne: vérifier les droits avant d'exposer "Ressources internes".
      -->
    </section>

    <section class="admin-card">
      <h2>Derniers tickets</h2>
      <p class="muted">La modération affiche le contenu tel quel (simulation).</p>

      <div class="ticket"><strong>#451</strong> — Problème d’affichage</div>
      <div class="ticket"><strong>#452</strong> — Suggestion UX</div>
      <div class="ticket warning"><strong>#453</strong> — Contenu inattendu détecté</div>
    </section>

  </main>

</div>

<footer class="admin-footer">
  IntraNova © 2026 — Interface interne confidentielle (simulation)
</footer>

</body>
</html>
PHP

# -------------------------
# grant_internal.php
# -------------------------
cat > "${SITE_DIR}/grant_internal.php" <<'PHP'
<?php
session_start();
$_SESSION["internal_ok"] = true;
header("Location: intranet.php");
exit;
PHP

# -------------------------
# logout_internal.php
# -------------------------
cat > "${SITE_DIR}/logout_internal.php" <<'PHP'
<?php
session_start();
unset($_SESSION["internal_ok"]);
header("Location: admin.php?internal=1");
exit;
PHP

# -------------------------
# intranet.php
# -------------------------
cat > "${SITE_DIR}/intranet.php" <<'PHP'
<?php
session_start();

if (!isset($_SESSION["internal_ok"]) || $_SESSION["internal_ok"] !== true) {
  http_response_code(403);
  echo "<h1>Accès refusé</h1>";
  echo "<p>Zone intranet interne (simulation).</p>";
  echo "<p><a href='admin.php?internal=1'>Retour admin</a></p>";
  exit;
}

$dir = __DIR__ . "/sensitive";
$files = [];
if (is_dir($dir)) {
  $files = array_values(array_filter(scandir($dir), fn($f) => $f !== "." && $f !== ".."));
}
?>
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>IntraNova · Intranet interne</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>

<header class="admin-topbar">
  <div class="admin-logo">IntraNova <span>Intranet interne</span></div>
  <div class="admin-user">
    Accès : <strong>Interne</strong> · <a class="toplink" href="admin.php?internal=1">Administration</a>
  </div>
</header>

<div class="admin-layout">
  <aside class="admin-sidebar">
    <h3>Intranet</h3>
    <ul>
      <li class="active">🏠 Accueil</li>
      <li>📄 Documents</li>
      <li>🧑‍🤝‍🧑 RH</li>
      <li>💻 IT</li>
      <li>📣 Annonces</li>
    </ul>
  </aside>

  <main class="admin-content">
    <h1>Documents internes</h1>
    <p class="admin-subtitle">Données fictives pour la démonstration.</p>

    <section class="admin-card">
      <h2>📁 Répertoire /sensitive</h2>

      <?php if (count($files) === 0): ?>
        <p class="muted">Aucun fichier.</p>
      <?php else: ?>
        <div class="file-list">
          <?php foreach ($files as $f): ?>
            <div class="file-item">
              <div class="file-name"><?php echo htmlspecialchars($f); ?></div>
              <div class="file-actions">
                <a class="link" href="sensitive/<?php echo rawurlencode($f); ?>" download>Télécharger</a>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>

      <p style="margin-top:14px;">
        <a class="admin-btn secondary" href="logout_internal.php">Quitter l’intranet</a>
      </p>
    </section>
  </main>
</div>

<footer class="admin-footer">
  IntraNova © 2026 — Intranet interne (simulation)
</footer>

</body>
</html>
PHP

# -------------------------
# style.css
# -------------------------
cat > "${SITE_DIR}/style.css" <<'CSS'
* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  background: #0f172a;
  color: #e5e7eb;
}

.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 32px;
  background: linear-gradient(90deg, #0f766e, #1e3a8a);
}

.logo { font-size: 20px; font-weight: 600; }
.logo span { font-weight: 400; opacity: 0.8; }

.badge {
  background: #022c22;
  color: #34d399;
  padding: 6px 12px;
  border-radius: 999px;
  text-decoration: none;
  font-size: 13px;
}

.container { max-width: 900px; margin: 40px auto; padding: 0 20px; }
.subtitle { color: #9ca3af; max-width: 760px; }

.card {
  margin-top: 18px;
  background: #020617;
  border: 1px solid #1f2933;
  border-radius: 14px;
  padding: 22px;
}

label { display: block; margin-bottom: 8px; color: #cbd5f5; }

input {
  width: 100%;
  padding: 12px;
  background: #020617;
  border: 1px solid #334155;
  border-radius: 8px;
  color: white;
  margin-bottom: 14px;
}

button {
  background: #2563eb;
  border: none;
  color: white;
  padding: 10px 16px;
  border-radius: 8px;
  cursor: pointer;
}

.render { margin-top: 22px; }
.hint { font-size: 13px; color: #94a3b8; }

.output {
  margin-top: 10px;
  padding: 14px;
  background: #020617;
  border: 1px dashed #334155;
  border-radius: 8px;
}

.empty { color: #64748b; }
.muted { color: #9ca3af; }

/* Admin */
.admin-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 32px;
  background: #020617;
  border-bottom: 1px solid #1e293b;
}

.admin-logo { font-size: 20px; font-weight: 600; }
.admin-logo span { font-weight: 400; opacity: 0.7; }
.admin-user { font-size: 14px; color: #cbd5f5; }

.admin-layout { display: flex; min-height: calc(100vh - 70px); }

.admin-sidebar {
  width: 220px;
  background: #020617;
  border-right: 1px solid #1e293b;
  padding: 20px;
}

.admin-sidebar h3 {
  margin-top: 0;
  font-size: 14px;
  text-transform: uppercase;
  color: #94a3b8;
}

.admin-sidebar ul { list-style: none; padding: 0; margin: 0; }
.admin-sidebar li { padding: 10px; border-radius: 8px; color: #cbd5f5; }
.admin-sidebar li.active { background: #1e293b; font-weight: 600; }

.admin-content { flex: 1; padding: 30px; }
.admin-subtitle { color: #9ca3af; max-width: 700px; }

.admin-card {
  background: #020617;
  border: 1px solid #1e293b;
  border-radius: 14px;
  padding: 20px;
  margin-top: 24px;
}

.admin-info { list-style: none; padding: 0; }
.admin-info li { margin-bottom: 6px; }

.admin-meta {
  margin-top: 12px;
  font-size: 13px;
  display: flex;
  gap: 10px;
  align-items: center;
}

.stealth-link {
  color: #64748b;
  text-decoration: none;
  border-bottom: 1px dotted #334155;
  padding-bottom: 1px;
}
.stealth-link:hover {
  color: #93c5fd;
  border-bottom-color: #93c5fd;
}

.admin-btn {
  display: inline-block;
  background: #2563eb;
  border: none;
  color: white;
  padding: 12px 18px;
  border-radius: 10px;
  cursor: pointer;
  font-size: 14px;
  text-decoration: none;
}
.admin-btn.secondary { background: #1e293b; }
.admin-btn.secondary:hover { background: #334155; }

.admin-footer {
  text-align: center;
  padding: 14px;
  font-size: 12px;
  color: #64748b;
  border-top: 1px solid #1e293b;
}

.toplink { color: #93c5fd; text-decoration: none; }
.toplink:hover { text-decoration: underline; }

.file-list { margin-top: 12px; }
.file-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid #1e293b;
  margin-top: 10px;
}
.file-name { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
.file-actions .link { color: #93c5fd; text-decoration: none; }
.file-actions .link:hover { text-decoration: underline; }

.ticket {
  padding: 10px;
  border-radius: 8px;
  border: 1px solid #1e293b;
  margin-top: 10px;
}
.ticket.warning { border-color: #7c2d12; background: #1c1917; }

@media (max-width: 900px) {
  .admin-layout { flex-direction: column; }
  .admin-sidebar { width: auto; }
}
CSS

# -------------------------
# Fichiers sensibles réalistes + flag caché
# -------------------------
cat > "${SENS_DIR}/it-change-log.txt" <<'TXT'
IntraNova — IT Change Log (Internal)
==================================

2026-01-03 09:14  DEPLOY  intranet01  Update nginx ruleset
2026-01-03 10:02  HOTFIX  files01     Patch ACL misconfiguration (shared folder)
2026-01-04 18:40  AUDIT   secops      Review ticket rendering pipeline

Note: During audit, an internal token was referenced in incident notes:
FLAG{INTRANOVA_INTERNAL_2026}
TXT

cat > "${SENS_DIR}/hr-export.csv" <<'CSV'
employee_id,first_name,last_name,department,email,office
101,Lina,Benali,HR,l.benali@intranova.test,PAR-2F
102,Mehdi,Kacem,IT,mehdi.kacem@intranova.test,PAR-3F
103,Sarah,Nguyen,Finance,sarah.nguyen@intranova.test,PAR-4F
CSV

cat > "${SENS_DIR}/backup_report.txt" <<'TXT'
Backup Report — Internal (Fictional)
===================================

Job: nightly_full
Target: files01:/exports
Status: OK
Duration: 00:03:18
Notes: No anomalies detected.
TXT

echo "✅ Installation terminée dans: ${LAB_ROOT}"
echo "▶️ Lancer : cd \"${SITE_DIR}\" && php -S 0.0.0.0:8080"
echo "🌐 NAT : http://localhost:8080/index.php"
echo "🌐 Bridge : http://IP_DE_LA_VM:8080/index.php"
echo
echo "ℹ️ Accès admin (simulation) : http://.../admin.php?internal=1"


