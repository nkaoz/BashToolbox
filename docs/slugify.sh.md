# slugify.sh

Convierte nombres de archivo a formato slug: minúsculas, sin acentos y con guiones en lugar de espacios o caracteres especiales. Por defecto, muestra el nombre resultante sin modificar el archivo.

Solo usa utilidades incluidas en macOS, por lo que no necesita dependencias adicionales.

## Uso

```sh
slugify.sh [opciones] archivo...
```

## Opciones

- `-r`, `--rename`: renombra los archivos.
- `-n`, `--dry-run`: simula el renombrado sin modificar archivos.
- `-p`, `--prefix TEXTO`: agrega un prefijo al slug.
- `-s`, `--suffix TEXTO`: agrega un sufijo al slug.
- `-e`, `--ext`: conserva la extensión original (comportamiento por defecto).
- `-h`, `--help`: muestra la ayuda.

Las extensiones se conservan y pasan a minúsculas.

## Ejemplos

```sh
slugify.sh "Mi Archivo Ñoño.txt"
slugify.sh -n *.pdf
slugify.sh -r -p "2026-" "Reporte Final.pdf"
slugify.sh -r -s "-aprobado" *.docx
```
