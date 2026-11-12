#!/usr/bin/env bash
#
# slugify.sh - Convierte nombres de archivos a formato slug
#
# Uso:
#   ./slugify.sh archivo.txt              # Solo muestra el nuevo nombre
#   ./slugify.sh -r archivo.txt           # Renombra el archivo
#   ./slugify.sh -r *.txt                 # Renombra varios archivos
#   ./slugify.sh -r -p "prefijo-" *.md    # Añade prefijo
#

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función de ayuda
usage() {
  cat <<EOF
Uso: $(basename "$0") [OPCIONES] archivo1 [archivo2 ...]

Opciones:
  -r, --rename     Renombra el archivo (por defecto solo muestra el resultado)
  -p, --prefix TXT Añade un prefijo al slug
  -s, --suffix TXT Añade un sufijo al slug
  -e, --ext         Conserva la extensión original (por defecto: sí)
  -n, --dry-run     Simula el renombrado sin hacer cambios
  -h, --help        Muestra esta ayuda

Ejemplos:
  $(basename "$0") "Mi Archivo Ñoño.txt"
  $(basename "$0") -r "Reporte Final 2024.pdf"
  $(basename "$0") -r -n *.txt
EOF
  exit 0
}

# Función para convertir texto a slug
slugify() {
  local input="$1"
  local slug

  # Convertir a minúsculas
  slug=$(echo "$input" | tr '[:upper:]' '[:lower:]')

  # Reemplazar caracteres acentuados y especiales del español
  slug=$(echo "$slug" | sed -e '
        s/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g;
        s/à/a/g; s/è/e/g; s/ì/i/g; s/ò/o/g; s/ù/u/g;
        s/ä/a/g; s/ë/e/g; s/ï/i/g; s/ö/o/g; s/ü/u/g;
        s/â/a/g; s/ê/e/g; s/î/i/g; s/ô/o/g; s/û/u/g;
        s/ã/a/g; s/õ/o/g;
        s/ñ/n/g; s/ç/c/g;
        s/ý/y/g;
    ')

  # Reemplazar cualquier carácter no alfanumérico por guion
  slug=$(echo "$slug" | sed -E 's/[^a-z0-9]+/-/g')

  # Eliminar guiones al inicio y final
  slug=$(echo "$slug" | sed -E 's/^-+|-+$//g')

  # Colapsar múltiples guiones consecutivos
  slug=$(echo "$slug" | sed -E 's/-+/-/g')

  echo "$slug"
}

# Valores por defecto
RENAME=false
DRY_RUN=false
PREFIX=""
SUFFIX=""
KEEP_EXT=true

# Parsear argumentos
FILES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  -r | --rename)
    RENAME=true
    shift
    ;;
  -n | --dry-run)
    DRY_RUN=true
    RENAME=true
    shift
    ;;
  -p | --prefix)
    [[ $# -ge 2 ]] || { echo "Falta el valor para $1" >&2; exit 2; }
    PREFIX="$2"
    shift 2
    ;;
  -s | --suffix)
    [[ $# -ge 2 ]] || { echo "Falta el valor para $1" >&2; exit 2; }
    SUFFIX="$2"
    shift 2
    ;;
  -e | --ext)
    KEEP_EXT=true
    shift
    ;;
  -h | --help) usage ;;
  -*)
    echo -e "${RED}Opción desconocida: $1${NC}" >&2
    usage
    ;;
  *)
    FILES+=("$1")
    shift
    ;;
  esac
done

# Validar que haya archivos
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo -e "${RED}Error: no se especificaron archivos${NC}" >&2
  usage
fi

# Procesar cada archivo
for file in "${FILES[@]}"; do
  if [[ ! -e "$file" ]]; then
    echo -e "${RED}[✗]${NC} No existe: $file" >&2
    continue
  fi

  # Separar nombre y extensión
  dir=$(dirname "$file")
  base=$(basename "$file")
  ext="${base##*.}"
  name="${base%.*}"

  # Si no hay extensión, el nombre completo es el nombre
  if [[ "$ext" == "$base" ]]; then
    name="$base"
    ext=""
  fi

  # Generar slug del nombre
  slug_name=$(slugify "$name")

  # Aplicar prefijo/sufijo
  [[ -n "$PREFIX" ]] && slug_name="${PREFIX}${slug_name}"
  [[ -n "$SUFFIX" ]] && slug_name="${slug_name}${SUFFIX}"

  # Construir el nuevo nombre
  if $KEEP_EXT && [[ -n "$ext" ]]; then
    new_name="${slug_name}.$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  else
    new_name="$slug_name"
  fi

  new_path="$dir/$new_name"

  # Si ya tiene el nombre correcto
  if [[ "$file" == "$new_path" ]]; then
    echo -e "${YELLOW}[=]${NC} Ya está en slug: $file"
    continue
  fi

  # Ejecutar o mostrar
  if $RENAME; then
    if [[ -e "$new_path" ]]; then
      echo -e "${RED}[✗]${NC} Ya existe destino: $new_path" >&2
      continue
    fi

    if $DRY_RUN; then
      echo -e "${YELLOW}[dry]${NC} $file → $new_path"
    else
      mv -- "$file" "$new_path"
      echo -e "${GREEN}[✓]${NC} $file → $new_path"
    fi
  else
    echo -e "${GREEN}[→]${NC} $file → $new_path"
  fi
done
