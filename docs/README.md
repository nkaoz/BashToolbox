# BashToolbox

Colección de scripts Bash para automatizar tareas cotidianas en macOS y Linux. Cada herramienta es independiente y tiene su propia página de documentación.

## Herramientas

| Comando | Descripción | Documentación |
| --- | --- | --- |
| `imgopt.sh` | Convierte y optimiza imágenes a JPEG. | [imgopt.sh.md](imgopt.sh.md) |
| `slugify.sh` | Convierte nombres de archivo a formato slug. | [slugify.sh.md](slugify.sh.md) |

## Requisitos

- Bash 3.2 o superior (incluido en macOS).
- macOS o Linux.
- Las dependencias externas indicadas en la documentación de cada herramienta.

## Instalación global en macOS

### 1. Instalar dependencias con MacPorts

Actualiza MacPorts e instala las herramientas requeridas por `imgopt.sh`:

```sh
sudo port selfupdate
sudo port install ImageMagick7 exiftool jpegoptim
```

Se usa `ImageMagick7` porque el script invoca el comando `magick`. Para comprobar que las dependencias están disponibles:

```sh
command -v magick exiftool jpegoptim
```

`slugify.sh` solo usa utilidades incluidas en macOS y no necesita dependencias adicionales.

### 2. Copiar los scripts a `~/bin`

Desde la carpeta de este proyecto, ejecuta:

```sh
mkdir -p "$HOME/bin"
cp imgopt.sh slugify.sh "$HOME/bin/"
chmod +x "$HOME/bin/imgopt.sh" "$HOME/bin/slugify.sh"
```

### 3. Añadir `~/bin` al `PATH`

Si usas zsh, añade esta línea a tu `~/.zshrc`:

```sh
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
```

Abre una terminal nueva o carga la configuración actual:

```sh
source "$HOME/.zshrc"
```

Comprueba que ambos comandos se encuentran disponibles:

```sh
command -v imgopt.sh slugify.sh
```

Ahora puedes ejecutarlos desde cualquier directorio. Para actualizar la instalación, vuelve a copiar los scripts a `~/bin` con el comando anterior.

## Uso

Cada herramienta documenta sus argumentos, opciones y ejemplos en su página correspondiente. También puedes consultar la ayuda desde la terminal:

```sh
imgopt.sh --help
slugify.sh --help
```
