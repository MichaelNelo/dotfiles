# Guix Home Configuration

Configuración declarativa del entorno de usuario usando Guix Home.

## Estructura del proyecto

```
guix/
├── home.scm           # Configuración principal de Guix Home
├── channels.scm       # Canales de Guix
└── packages/
    ├── doom.scm       # Paquete de Doom Emacs
    ├── omz.scm        # Paquete de Oh My Zsh
    └── claude-code.scm # Paquete de Claude Code
```

## Componentes principales en home.scm

- **Paquetes**: emacs-no-x, git, zsh, node, ripgrep, fzf, direnv, zoxide, etc.
- **Servicios**:
  - `home-dotfiles-service-type`: Gestión de dotfiles
  - `emacs-daemon` (Shepherd): Daemon de Emacs con variables de Doom
  - `home-openssh-service-type`: Configuración SSH (hosts para GitHub)
  - `doom-emacs-installation`: Activación que instala/sincroniza Doom
  - `home-zsh-service-type`: Configuración de ZSH con variables de entorno

## Variables de entorno de Doom Emacs

| Variable | Propósito | Valor |
|----------|-----------|-------|
| `DOOMDIR` | Configuración personal del usuario (init.el, packages.el) | `~/.config/doom` |
| `EMACSDIR` | Donde está instalado Doom Emacs | `~/.config/emacs` |
| `DOOMLOCALDIR` | Datos/cache de Doom (paquetes, .elc, autoloads) | Por defecto: `$EMACSDIR/.local` |

---

## Historial de problemas resueltos

### 2026-01-13: Error `void-variable doom-modules` en Shepherd

**Síntoma:**
```
2026-01-13 21:32:51 Starting Emacs daemon.
2026-01-13 21:32:51 Error in a Doom startup hook: doom-after-init-hook, doom-display-benchmark-h, (void-variable doom-modules)
```

**Causa raíz:**
`DOOMLOCALDIR` estaba configurado incorrectamente como `~/.config/doom`, que es el mismo valor que `DOOMDIR` (configuración personal). Esto causaba que Doom buscara sus archivos compilados y datos en el lugar equivocado.

**Pasos de diagnóstico:**
1. Revisamos `home.scm` y encontramos `DOOMLOCALDIR` definido en dos lugares:
   - Servicio Shepherd (línea 85): `DOOMLOCALDIR=$HOME/.config/doom`
   - Variables de ZSH (línea 153): `DOOMLOCALDIR=$HOME/.config/doom`
2. Verificamos que `~/.config/emacs/.local` no existía
3. Confirmamos que `~/.config/emacs` sí tiene permisos de escritura

**Solución aplicada:**
Eliminamos `DOOMLOCALDIR` de ambos lugares para que Doom use el valor por defecto `$EMACSDIR/.local`:

```diff
# En el servicio Shepherd:
- (list (string-append "DOOMDIR=" home "/.config/doom")
-       (string-append "EMACSDIR=" home "/.config/emacs")
-       (string-append "DOOMLOCALDIR=" home "/.config/doom"))
+ (list (string-append "DOOMDIR=" home "/.config/doom")
+       (string-append "EMACSDIR=" home "/.config/emacs"))

# En variables de ZSH:
- ("DOOMLOCALDIR"   .  "$HOME/.config/doom")
```

**Pasos para aplicar:**
```bash
guix home reconfigure home.scm
~/.config/emacs/bin/doom sync
```
