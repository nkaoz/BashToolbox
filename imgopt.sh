#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Image Optimizer
# Compatible: macOS / Linux
# ==========================================

PREFIX="${1:-imagen}"
INPUT_DIR="${2:-.}"
OUTPUT_DIR="${3:-./optimized}"
QUALITY="${4:-80}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/imgopt"

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

  for cmd in magick exiftool jpegoptim; do
    command -v "$cmd" >/dev/null 2>&1 ||
      error "Falta instalar '$cmd'"
  done
}

# ------------------------------------------
# Validaciones
# ------------------------------------------

[[ "$PREFIX" =~ ^[a-zA-Z0-9_-]+$ ]] ||
  error "El prefijo solo admite letras, números, _ y -"

[[ "$QUALITY" =~ ^[0-9]+$ ]] ||
  error "La calidad debe ser un número entre 1 y 100"

((QUALITY >= 1 && QUALITY <= 100)) ||
  error "La calidad debe estar entre 1 y 100"

[[ -d "$INPUT_DIR" ]] ||
  error "No existe el directorio: $INPUT_DIR"

check_dependencies

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

# ------------------------------------------
# Procesamiento
# ------------------------------------------

procesadas=0
omitidas=0

while IFS= read -r -d '' archivo; do

  nombre_archivo="${archivo##*/}"

  # Omitir archivos marcados
  if [[ "$nombre_archivo" == _* ]]; then
    printf '%sOmitiendo: %s%s\n' "$COLOR_DIM" "$archivo" "$COLOR_RESET"
    omitidas=$((omitidas + 1))
    continue
  fi

  # Evitar sobrescritura
  while :; do
    printf -v nuevo_nombre \
      '%s-%02d.jpg' "$PREFIX" "$contador"

    destino="$OUTPUT_DIR/$nuevo_nombre"

    [[ ! -e "$destino" ]] && break

    contador=$((contador + 1))
  done

  temporal="$OUTPUT_DIR/.${nuevo_nombre}.tmp.jpg"

  # No reutilizar un temporal existente
  [[ ! -e "$temporal" ]] ||
    error "Existe un temporal pendiente: $temporal"

  printf '\n%s\n' '----------------------------------------'
  printf '%sProcesando:%s %s\n' "$COLOR_BOLD$COLOR_CYAN" "$COLOR_RESET" "$archivo"

  original_size="$(file_size "$archivo")"

  # Convertir a JPEG
  if ! magick "$archivo" \
    -auto-orient \
    -background white \
    -alpha remove \
    -alpha off \
    -strip \
    -sampling-factor 4:2:0 \
    -interlace Plane \
    -quality "$QUALITY" \
    "$temporal"; then

    rm -f "$temporal"
    error "Falló ImageMagick: $archivo"
  fi

  # Eliminar metadatos
  if ! exiftool \
    -all= \
    -overwrite_original \
    "$temporal" >/dev/null; then

    rm -f "$temporal"
    error "Falló ExifTool: $archivo"
  fi

  # Optimizar JPEG
  if ! jpegoptim \
    --strip-all \
    --max="$QUALITY" \
    --all-progressive \
    "$temporal" >/dev/null; then

    rm -f "$temporal"
    error "Falló jpegoptim: $archivo"
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
    -o -iname '*.webp' \) \
    -print0
)

# ------------------------------------------
# Resumen
# ------------------------------------------

printf '\n%s\n' '========================================'
printf '%s✓ Proceso terminado%s\n' "$COLOR_BOLD$COLOR_GREEN" "$COLOR_RESET"
printf 'Procesadas: %s%s%s\n' "$COLOR_GREEN" "$procesadas" "$COLOR_RESET"
printf 'Omitidas:   %s%s%s\n' "$COLOR_YELLOW" "$omitidas" "$COLOR_RESET"
printf 'Formato:    JPG\n'
printf 'Destino:    %s\n' "$OUTPUT_DIR"
printf '%s\n' '========================================'
