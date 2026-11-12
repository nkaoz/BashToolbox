#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Image Optimizer
# Compatible: macOS / Linux
# ==========================================

PREFIX="optimize"
INPUT_DIR="."
OUTPUT_DIR="./optimized"
QUALITY="85"

COMMAND_NAME="$(basename "$0")"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/imgopt"
HEIC_BACKEND=""
FORMAT="jpg"
EXTENSION="jpg"
FORMAT_LABEL="JPG"
FORMAT_OPT=""

# ------------------------------------------
# Colores (solo si la salida es una terminal)
# ------------------------------------------

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  COLOR_RESET=$'\033[0m'
  COLOR_BOLD=$'\033[1m'
  COLOR_DIM=$'\033[2m'
  COLOR_RED=$'\033[31m'
  COLOR_GREEN=$'\033[32m'
  COLOR_YELLOW=$'\033[33m'
  COLOR_CYAN=$'\033[36m'
else
  COLOR_RESET=''
  COLOR_BOLD=''
  COLOR_DIM=''
  COLOR_RED=''
  COLOR_GREEN=''
  COLOR_YELLOW=''
  COLOR_CYAN=''
fi

# ------------------------------------------
# Utilidades
# ------------------------------------------

error() {
  printf '%sError: %s%s\n' "$COLOR_RED" "$*" "$COLOR_RESET" >&2
  exit 1
}

usage() {
  cat <<EOF
${COLOR_BOLD}Uso:${COLOR_RESET} ${COMMAND_NAME} [opciones]

Convierte imágenes JPG, PNG, WebP y HEIC/HEIF a JPG o WebP optimizado.

Al ejecutarlo sin opciones usa: entrada ., prefijo optimize, formato jpg, calidad 85 y salida ./optimized.

${COLOR_BOLD}Opciones:${COLOR_RESET}
  -p, --prefix TEXTO    Prefijo de los archivos de salida (defecto: optimize)
  -i, --input DIR       Carpeta con las imágenes (defecto: .)
  -o, --output DIR      Carpeta destino (defecto: ./optimized)
  -q, --quality N       Calidad de 1 a 100 (defecto: 85)
  -f, --format FORMATO  Formato de salida: jpg o webp (defecto: jpg)
  -h, --help            Muestra esta ayuda

${COLOR_BOLD}Ejemplos:${COLOR_RESET}
  ${COMMAND_NAME} --prefix viaje --input ./fotos --output ./fotos-optimizadas --quality 85
  ${COMMAND_NAME} --format webp --prefix viaje
EOF
}

color_nivel() {
  local porcentaje="$1"

  if ((porcentaje >= 50)); then
    printf '%s' "$COLOR_GREEN"
  elif ((porcentaje >= 25)); then
    printf '%s' "$COLOR_CYAN"
  elif ((porcentaje >= 10)); then
    printf '%s' "$COLOR_YELLOW"
  else
    printf '%s' "$COLOR_RED"
  fi
}

etiqueta_nivel() {
  local porcentaje="$1"

  if ((porcentaje >= 50)); then
    printf 'Excelente'
  elif ((porcentaje >= 25)); then
    printf 'Buena'
  elif ((porcentaje >= 10)); then
    printf 'Moderada'
  else
    printf 'Baja'
  fi
}

file_size() {
  local file="$1"

  if stat -f%z "$file" >/dev/null 2>&1; then
    stat -f%z "$file"
  else
    stat -c%s "$file"
  fi
}

human_size() {
  local bytes="$1"
  local units=(B KiB MiB GiB TiB)
  local index=0

  while ((bytes >= 1024 && index < 4)); do
    bytes=$((bytes / 1024))
    index=$((index + 1))
  done

  printf '%s %s' "$bytes" "${units[$index]}"
}

check_dependencies() {
  local cmd

  for cmd in magick exiftool; do
    command -v "$cmd" >/dev/null 2>&1 ||
      error "Falta instalar '$cmd'"
  done
}

es_heic() {
  local extension="${1##*.}"

  extension="$(printf '%s' "$extension" | tr '[:upper:]' '[:lower:]')"

  [[ "$extension" == "heic" || "$extension" == "heif" ]]
}

detectar_soporte_heic() {
  if magick -list format 2>/dev/null |
    awk '$1 == "HEIC" && $3 ~ /r/ { encontrado = 1 } END { exit !encontrado }'; then
    HEIC_BACKEND="magick"
  elif command -v sips >/dev/null 2>&1; then
    HEIC_BACKEND="sips"
  elif command -v heif-convert >/dev/null 2>&1; then
    HEIC_BACKEND="heif-convert"
  else
    HEIC_BACKEND=""
  fi
}

# ------------------------------------------
# Validaciones
# ------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -p | --prefix)
      [[ $# -ge 2 ]] || error "Falta el valor para $1"
      PREFIX="$2"
      shift 2
      ;;
    -i | --input)
      [[ $# -ge 2 ]] || error "Falta el valor para $1"
      INPUT_DIR="$2"
      shift 2
      ;;
    -o | --output)
      [[ $# -ge 2 ]] || error "Falta el valor para $1"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -q | --quality)
      [[ $# -ge 2 ]] || error "Falta el valor para $1"
      QUALITY="$2"
      shift 2
      ;;
    -f | --format)
      [[ $# -ge 2 ]] || error "Falta el valor para $1"
      FORMAT_OPT="$2"
      shift 2
      ;;
    -*)
      error "Opción desconocida: $1 (usa --help para ver las opciones)"
      ;;
    *)
      error "Argumento no reconocido: $1 (usa --help para ver las opciones)"
      ;;
  esac
done

if [[ -n "$FORMAT_OPT" ]]; then
  case "$(printf '%s' "$FORMAT_OPT" | tr '[:upper:]' '[:lower:]')" in
    jpg | jpeg) ;;
    webp)
      FORMAT="webp"
      EXTENSION="webp"
      FORMAT_LABEL="WEBP"
      ;;
    *)
      error "Formato no válido: $FORMAT_OPT (usa jpg o webp)"
      ;;
  esac
fi

[[ "$PREFIX" =~ ^[a-zA-Z0-9_-]+$ ]] ||
  error "El prefijo solo admite letras, números, _ y -"

[[ "$QUALITY" =~ ^[0-9]+$ ]] ||
  error "La calidad debe ser un número entre 1 y 100"

((QUALITY >= 1 && QUALITY <= 100)) ||
  error "La calidad debe estar entre 1 y 100"

[[ -d "$INPUT_DIR" ]] ||
  error "No existe el directorio: $INPUT_DIR"

check_dependencies
detectar_soporte_heic

mkdir -p "$OUTPUT_DIR" "$STATE_DIR"

INPUT_DIR="$(cd "$INPUT_DIR" && pwd -P)"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"

[[ "$INPUT_DIR" != "$OUTPUT_DIR" ]] ||
  error "Entrada y salida deben ser diferentes"

COUNTER_FILE="$STATE_DIR/${PREFIX}.counter"

if [[ -f "$COUNTER_FILE" ]]; then
  IFS= read -r contador <"$COUNTER_FILE" || true
else
  contador=1
fi

[[ "$contador" =~ ^[0-9]+$ ]] ||
  error "Contador inválido"

if [[ "$FORMAT" == "jpg" ]]; then
  command -v jpegoptim >/dev/null 2>&1 ||
    error "Falta instalar 'jpegoptim'"
fi

# ------------------------------------------
# Procesamiento
# ------------------------------------------

procesadas=0
omitidas=0

while IFS= read -r -d '' archivo; do

  nombre_archivo="${archivo##*/}"
  decodificado=""

  # Omitir archivos marcados
  if [[ "$nombre_archivo" == _* ]]; then
    printf '%sOmitiendo: %s%s\n' "$COLOR_DIM" "$archivo" "$COLOR_RESET"
    omitidas=$((omitidas + 1))
    continue
  fi

  # Evitar sobrescritura
  while :; do
    printf -v nuevo_nombre \
      '%s-%02d.%s' "$PREFIX" "$contador" "$EXTENSION"

    destino="$OUTPUT_DIR/$nuevo_nombre"

    [[ ! -e "$destino" ]] && break

    contador=$((contador + 1))
  done

  temporal="$OUTPUT_DIR/.${nuevo_nombre}.tmp.${EXTENSION}"

  # No reutilizar un temporal existente
  [[ ! -e "$temporal" ]] ||
    error "Existe un temporal pendiente: $temporal"

  printf '\n%s\n' '----------------------------------------'
  printf '%sProcesando:%s %s\n' "$COLOR_BOLD$COLOR_CYAN" "$COLOR_RESET" "$archivo"

  original_size="$(file_size "$archivo")"

  entrada="$archivo"

  # Decodificar HEIC/HEIF si ImageMagick no puede leerlos directamente
  if es_heic "$archivo"; then
    [[ -n "$HEIC_BACKEND" ]] ||
      error "No hay soporte para HEIC/HEIF; instala libheif o usa macOS con sips: $archivo"

    if [[ "$HEIC_BACKEND" != "magick" ]]; then
      decodificado="$OUTPUT_DIR/.${nuevo_nombre}.tmp.png"

      [[ ! -e "$decodificado" ]] ||
        error "Existe un temporal pendiente: $decodificado"

      if [[ "$HEIC_BACKEND" == "sips" ]]; then
        if ! sips -s format png "$archivo" --out "$decodificado" >/dev/null; then
          rm -f "$decodificado"
          error "Falló sips al convertir HEIC: $archivo"
        fi
      else
        if ! heif-convert "$archivo" "$decodificado" >/dev/null; then
          rm -f "$decodificado"
          error "Falló heif-convert al convertir HEIC: $archivo"
        fi
      fi

      entrada="$decodificado"
    fi
  fi

  # Opciones según el formato de salida
  opciones_formato=()

  if [[ "$FORMAT" == "webp" ]]; then
    opciones_formato=(-define webp:method=6)
  else
    opciones_formato=(
      -background white
      -alpha remove
      -alpha off
      -sampling-factor 4:2:0
      -interlace Plane
    )
  fi

  # Convertir al formato elegido
  if ! magick "$entrada" \
    -auto-orient \
    "${opciones_formato[@]}" \
    -strip \
    -quality "$QUALITY" \
    "$temporal"; then

    rm -f "$temporal"
    [[ -z "$decodificado" ]] || rm -f "$decodificado"
    error "Falló ImageMagick: $archivo"
  fi

  [[ -z "$decodificado" ]] || rm -f "$decodificado"

  # Eliminar metadatos
  if ! exiftool \
    -all= \
    -overwrite_original \
    "$temporal" >/dev/null; then

    rm -f "$temporal"
    error "Falló ExifTool: $archivo"
  fi

  # Optimizar JPEG (WebP ya se comprime con ImageMagick)
  if [[ "$FORMAT" == "jpg" ]]; then
    if ! jpegoptim \
      --strip-all \
      --max="$QUALITY" \
      --all-progressive \
      "$temporal" >/dev/null; then

      rm -f "$temporal"
      error "Falló jpegoptim: $archivo"
    fi
  fi

  [[ -s "$temporal" ]] ||
    error "Archivo optimizado vacío: $temporal"

  final_size="$(file_size "$temporal")"

  ahorro=$((original_size - final_size))

  if ((original_size > 0)); then
    porcentaje=$((ahorro * 100 / original_size))
  else
    porcentaje=0
  fi

  # Verificar que el original pueda marcarse
  marcado="$INPUT_DIR/_$nombre_archivo"

  [[ ! -e "$marcado" ]] ||
    error "Ya existe el archivo: $marcado"

  # Publicar resultado
  mv "$temporal" "$destino"

  # Marcar original como procesado
  mv "$archivo" "$marcado"

  contador=$((contador + 1))

  printf '%s\n' "$contador" >"$COUNTER_FILE"

  procesadas=$((procesadas + 1))

  color="$(color_nivel "$porcentaje")"
  nivel="$(etiqueta_nivel "$porcentaje")"

  printf '%sArchivo:%s    %s\n' "$COLOR_DIM" "$COLOR_RESET" "$nuevo_nombre"
  printf '%sOriginal:%s   %s\n' "$COLOR_DIM" "$COLOR_RESET" "$(human_size "$original_size")"
  printf '%sOptimizado:%s %s%s%s\n' \
    "$COLOR_DIM" "$COLOR_RESET" "$color" "$(human_size "$final_size")" "$COLOR_RESET"
  printf '%sReducción:%s  %s%s%%%s\n' \
    "$COLOR_DIM" "$COLOR_RESET" "$color" "$porcentaje" "$COLOR_RESET"
  printf '%sNivel:%s      %s%s%s%s\n' \
    "$COLOR_DIM" "$COLOR_RESET" "$COLOR_BOLD" "$color" "$nivel" "$COLOR_RESET"

done < <(
  find "$INPUT_DIR" \
    -maxdepth 1 \
    -type f \
    \( -iname '*.jpg' \
    -o -iname '*.jpeg' \
    -o -iname '*.png' \
    -o -iname '*.webp' \
    -o -iname '*.heic' \
    -o -iname '*.heif' \) \
    -print0
)

# ------------------------------------------
# Resumen
# ------------------------------------------

printf '\n%s\n' '========================================'
printf '%s✓ Proceso terminado%s\n' "$COLOR_BOLD$COLOR_GREEN" "$COLOR_RESET"
printf 'Procesadas: %s%s%s\n' "$COLOR_GREEN" "$procesadas" "$COLOR_RESET"
printf 'Omitidas:   %s%s%s\n' "$COLOR_YELLOW" "$omitidas" "$COLOR_RESET"
printf 'Formato:    %s\n' "$FORMAT_LABEL"
printf 'Destino:    %s\n' "$OUTPUT_DIR"
printf '%s\n' '========================================'
