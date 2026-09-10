# Elek László SJ - Személyes weboldal

Jezsuita szerzetes és pap személyes blogja és információs oldala.

## 🚀 Automatikus Deployment

A projekt GitHub Actions workflow-mal rendelkezik, amely automatikusan deployolja az oldalt az Azure VM-re, amikor pusholsz a `master` branchre.

### Deployment folyamata:

1. **Push a master branchre** → GitHub Actions workflow indul
2. **Jekyll build** → Az oldal statikus HTML-re fordítódik
3. **SSH kapcsolat az Azure VM-hez** → A kód letöltődik
4. **Docker build és start** → A container felépül és elindul
5. **Nginx proxy** → Az oldal elérhető a https://eleklaszlo.hu címen

### Szükséges GitHub Secrets:

A deployment működéséhez az alábbi secrets-eket kell beállítani a GitHub repository Settings → Secrets and variables → Actions menüben:

- `AZURE_VM_HOST` - Az Azure VM IP címe vagy hostname-je
- `AZURE_VM_USER` - SSH felhasználónév (pl. `azureuser`)
- `AZURE_VM_SSH_KEY` - Az SSH privát kulcs

## 🏗️ Lokális fejlesztés - Jekyll build

Mielőtt commitolsz, teszteld le az oldalt lokálisan, hogy biztosan működik.

### Előfeltételek:

- Docker és Docker Compose telepítve
- vagy Ruby 3.0+ és bundler

### Opció 1: Docker-rel (ajánlott)

```bash
# Build a Docker image
docker compose build

# Indítsd el a fejlesztő szervert
docker compose up

# Az oldal elérhető lesz a http://localhost:5001 címen
```

A container automatikusan figyeli a fájlok változásait és újraépíti az oldalt.

### Opció 2: Lokális Ruby-val

```bash
# Telepítsd a gem-eket
bundle install

# Indítsd el a Jekyll fejlesztő szervert
bundle exec jekyll serve --host 0.0.0.0 --port 4000

# Az oldal elérhető lesz a http://localhost:4000 címen
```

### Módosítások tesztelése:

1. Szerkeszd meg a fájlokat (`_posts/`, `_pages/`, `_layouts/`, stb.)
2. Mentsd el a fájlokat
3. Frissítsd a böngészőt - a Jekyll automatikusan újraépíti az oldalt
4. Ellenőrizd, hogy az oldal helyesen jelenik meg
5. Ha minden OK, commitolj és pusholj a `master` branchre

## 📁 Projekt szerkezete

```
.
├── _posts/              # Blog bejegyzések (Markdown)
├── _pages/              # Statikus oldalak
├── _layouts/            # HTML sablonok
├── _includes/           # Újrafelhasználható HTML komponensek
├── _plugins/            # Jekyll pluginok
├── files/               # Képek, PDF-ek és egyéb média
├── _config.yml          # Jekyll konfigurációs fájl
├── Dockerfile           # Docker image definíció
├── docker-compose.yml   # Docker Compose konfigurációs fájl
├── nginx.conf           # Nginx webszerver konfigurációs fájl
├── deploy.sh            # Deployment script az Azure VM-en
└── Gemfile              # Ruby gem függőségek
```

## 🔧 Konfigurációs fájlok

### `_config.yml`

A Jekyll konfigurációs fájl. Itt lehet beállítani:
- Az oldal címét, leírását
- Szociális média linkeket
- Pluginokat
- Paginációt

### `Dockerfile`

Multi-stage build:
1. **Builder stage**: Jekyll fordítás Ruby-val
2. **Final stage**: Nginx webszerver a fordított HTML-lel

### `docker-compose.yml`

Docker container konfigurációja:
- Port: `5001:80`
- Automatikus restart
- Health check
- Timezone: Europe/Budapest

## 📝 Bejegyzések írása

### Blog bejegyzés (`_posts/`)

Fájlnév formátum: `YYYY-MM-DD-title.markdown`

```markdown
---
layout: post
title: "Bejegyzés címe"
date: 2024-01-15 10:30:00 +0100
categories: [kategória1, kategória2]
tags: [tag1, tag2]
---

Bejegyzés tartalma...

<!--break-->

Folytatás az első oldal után...
```

### Statikus oldal (`_pages/`)

```markdown
---
layout: page
title: "Oldal címe"
permalink: /oldal-url/
---

Oldal tartalma...
```

## 🐳 Docker parancsok

```bash
# Build
docker compose build

# Indítás
docker compose up -d

# Leállítás
docker compose down

# Logok megtekintése
docker compose logs -f

# Container-be belépés
docker compose exec web sh
```

## 🔍 Hibaelhárítás

### Az oldal nem jelenik meg lokálisan

```bash
# Ellenőrizd a logokat
docker compose logs

# Vagy Ruby-val
bundle exec jekyll build --trace
```

### Port már használatban van

Módosítsd a `docker-compose.yml` fájlban a port mappinget:
```yaml
ports:
  - "5002:80"  # Másik port helyett
```

### Gemfile.lock problémák

```bash
# Frissítsd a gem-eket
bundle update

# Vagy töröld és újra telepítsd
rm Gemfile.lock
bundle install
```

## 📚 Hasznos linkek

- [Jekyll dokumentáció](https://jekyllrb.com/)
- [Markdown szintaxis](https://www.markdownguide.org/)
- [Docker dokumentáció](https://docs.docker.com/)

## 📧 Kapcsolat

Email: eleklaszlosj@gmail.com

---

**Utolsó frissítés**: 2024
