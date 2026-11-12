# Scripts de utilidad

Colección de herramientas Bash para optimizar imágenes y generar nombres de archivo en formato slug.

## `imgopt.sh`

Convierte imágenes JPEG, PNG y WebP del directorio de entrada a JPEG optimizados. Los originales procesados se renombran con `_` al inicio y los resultados se guardan en `optimized` de forma predeterminada.

```sh
./imgopt.sh [prefijo] [directorio_entrada] [directorio_salida] [calidad]
```

La calidad debe ser un valor entre 1 y 100. Requiere ImageMagick (`magick`), ExifTool (`exiftool`) y jpegoptim. Mantiene un contador por prefijo en `${XDG_STATE_HOME:-$HOME/.local/state}/imgopt`.

## `slugify.sh`

Muestra el nombre slugificado por defecto; `-r` ejecuta el renombrado y `-n` muestra una simulación.

```sh
./slugify.sh [-r] [-n] [-p prefijo] [-s sufijo] archivo...
```

Acepta varios archivos y conserva sus extensiones en minúsculas.
