---
name: hermes-version-control
description: Version control and sync your Hermes Agent "brain" (config, skills, SOUL) using a symlinked Git repository. Prevents loss of custom skills and enables syncing between machines while keeping sensitive data and large logs out of Git.
version: 1.0.0
author: Hermes Agent
---

# Hermes Agent Version Control

This skill describes the "Symlinked Config Repository" pattern for Hermes Agent. This allows you to track changes to your agent's configuration, custom skills, and personality (SOUL.md) in a Git repository while keeping the agent functional in its default `~/.hermes/` directory.

## Why use this?
- **Version History:** See how your agent's instructions and configuration evolve over time.
- **Easy Backup:** Push your "brain" to GitHub/GitLab.
- **Syncing:** Clone the repo on a new machine (e.g., a cloud server) and symlink to quickly replicate your agent's setup.

## Implementation Steps

### 1. Initialize the Repository
Create a directory for your agent's version-controlled files.
```bash
mkdir -p ~/projects/hermes-config
cd ~/projects/hermes-config
git init
```

### 2. Configure .gitignore (CRITICAL)
You must prevent sensitive keys and large state files from being tracked.
```text
# Security
.env
auth.json

# State and Data (Large/Private)
sessions/
logs/
memories/
audio_cache/
image_cache/
whatsapp/session/
cron/state/
*.db
*.db-shm
*.db-wal
.hermes_history
.update_check
.skills_prompt_snapshot.json
cache/
sandboxes/
pastes/
images/

# Environments
venv/
__pycache__/
```

### 3. Migrate and Symlink
Move the files you want to track into the repo, then link them back.

**What to track:**
- `config.yaml` (Agent settings)
- `skills/` (Custom skills)
- `SOUL.md` (Agent personality)
- `hooks/` & `cron/` (Automations)

**Example migration script:**
```bash
# Move to repo
mv ~/.hermes/config.yaml ~/projects/hermes-config/
mv ~/.hermes/skills ~/projects/hermes-config/
mv ~/.hermes/SOUL.md ~/projects/hermes-config/

# Symlink back
ln -s ~/projects/hermes-config/config.yaml ~/.hermes/config.yaml
ln -s ~/projects/hermes-config/skills ~/.hermes/skills
ln -s ~/projects/hermes-config/SOUL.md ~/.hermes/SOUL.md
```

### 4. Commit Changes
```bash
cd ~/projects/hermes-config
git add .
git commit -m "Initial agent configuration backup"
```

## Pitfalls & Tips
- **Absolute Paths:** When creating symlinks, use absolute paths to ensure they don't break if you move things around.
- **Sensitive Data:** Always double-check `git status` before committing to ensure no `.env` or `auth.json` files were accidentally added.
- **Cloud Sync:** If you push to a private repo, you can `git pull` on your DigitalOcean droplet or other remote servers to instantly update your agent's skills and settings.
- **Reloading:** After updating `config.yaml` via a symlink, you may need to restart the agent gateway or CLI for changes to take effect.
