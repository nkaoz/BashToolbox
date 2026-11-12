# Scripts de utilidad

Dos herramientas Bash para optimizar imágenes y convertir nombres de archivo a formato slug. `slugify.sh` solo usa utilidades incluidas en macOS; `imgopt.sh` necesita ImageMagick, ExifTool y jpegoptim.

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

### 2. Copiar los scripts a `~/bin`

Desde la carpeta de este proyecto, ejecuta:

```sh
mkdir -p "$HOME/bin"
cp imgopt.sh slugify.sh "$HOME/bin/"
chmod +x "$HOME/bin/imgopt.sh" "$HOME/bin/slugify.sh"
```

Agrega `~/bin` al `PATH` de zsh. Si ya tienes un `~/.zshrc`, puedes añadir esta línea:

```sh
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
```

Abre una terminal nueva o carga la configuración actual:

```sh
source "$HOME/.zshrc"
```

Comprueba que ambos comandos se encuentran:

```sh
command -v imgopt.sh slugify.sh
```

Ahora puedes ejecutarlos desde cualquier directorio. Para actualizar la instalación, vuelve a copiar los scripts a `~/bin` con el comando anterior.

## Optimizar imágenes: `imgopt.sh`

Convierte archivos JPEG, PNG y WebP del directorio indicado a JPEG. Procesa solo los archivos directamente dentro del directorio (no busca en subdirectorios). Los resultados se guardan en `./optimized` por defecto y el original se renombra con `_` al inicio para marcarlo como procesado.

```sh
imgopt.sh [prefijo] [directorio_entrada] [directorio_salida] [calidad]
```

- `prefijo`: prefijo del nombre de salida; por defecto, `imagen`.
- `directorio_entrada`: carpeta de imágenes; por defecto, el directorio actual.
- `directorio_salida`: carpeta para los JPEG generados; por defecto, `./optimized`.
- `calidad`: valor entre 1 y 100; por defecto, `80`.

Ejemplos:

```sh
imgopt.sh
imgopt.sh viaje ./fotos ./fotos-optimizadas 85
```

Los nombres generados llevan un contador (`viaje-01.jpg`, `viaje-02.jpg`, etc.). El contador se guarda en `${XDG_STATE_HOME:-$HOME/.local/state}/imgopt`.

## Convertir nombres a slug: `slugify.sh`

Por defecto, muestra el nombre resultante sin modificar el archivo. Con `-r` realiza el renombrado; `-n` muestra una simulación del renombrado.

```sh
slugify.sh [opciones] archivo...
```

Opciones disponibles:

- `-r`, `--rename`: renombra los archivos.
- `-n`, `--dry-run`: simula el renombrado sin modificar archivos.
- `-p`, `--prefix TEXTO`: agrega un prefijo al slug.
- `-s`, `--suffix TEXTO`: agrega un sufijo al slug.
- `-h`, `--help`: muestra la ayuda.

Las extensiones se conservan y pasan a minúsculas. Ejemplos:

```sh
slugify.sh "Mi Archivo Ñoño.txt"
slugify.sh -n *.pdf
slugify.sh -r -p "2026-" "Reporte Final.pdf"
slugify.sh -r -s "-aprobado" *.docx
```
