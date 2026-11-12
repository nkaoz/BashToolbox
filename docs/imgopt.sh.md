# imgopt.sh

Convierte archivos JPEG, PNG, WebP y HEIC/HEIF del directorio indicado a JPEG o WebP optimizado. Procesa solo los archivos directamente dentro del directorio (no busca en subdirectorios). Los resultados se guardan en `./optimized` por defecto y el original se renombra con `_` al inicio para marcarlo como procesado.

## Uso

```sh
imgopt.sh [opciones]
```

Ejecutar el comando sin opciones, o con `-h`/`--help`, muestra la ayuda.

## Opciones

- `-p`, `--prefix TEXTO`: prefijo del nombre de salida; por defecto, `imagen`.
- `-i`, `--input DIR`: carpeta de imágenes; por defecto, el directorio actual.
- `-o`, `--output DIR`: carpeta para los archivos generados; por defecto, `./optimized`.
- `-q`, `--quality N`: calidad entre 1 y 100; por defecto, `80`.
- `-f`, `--format FORMATO`: formato de salida, `jpg` o `webp`. Si se omite, el script lo pregunta.
- `-h`, `--help`: muestra la ayuda.

## Formato de salida

Si no se usa `--format`, el script pregunta si se desea generar **JPG** o **WEBP**. Si no hay respuesta en 10 segundos, usa JPG automáticamente.

Cuando no hay una terminal interactiva (por ejemplo, al redirigir la salida), también se usa JPG sin preguntar.

- **JPG**: se aplana la transparencia sobre fondo blanco y se optimiza con `jpegoptim`.
- **WEBP**: se conserva la transparencia y se comprime con ImageMagick usando el método más lento y de mayor calidad.

## Ejemplos

```sh
imgopt.sh
imgopt.sh --prefix viaje --input ./fotos --output ./fotos-optimizadas --quality 85
imgopt.sh --format webp --prefix viaje
```

Los nombres generados llevan un contador (`viaje-01.jpg`, `viaje-02.webp`, etc.). El contador se guarda en `${XDG_STATE_HOME:-$HOME/.local/state}/imgopt`.

Como los originales se renombran con `_` al inicio, una segunda ejecución los omite y no se procesan dos veces.

## Niveles de optimización

Los resultados se muestran en color según el nivel de optimización alcanzado:

- **Excelente** (verde): reducción del 50 % o más.
- **Buena** (cian): reducción entre 25 % y 49 %.
- **Moderada** (amarillo): reducción entre 10 % y 24 %.
- **Baja** (rojo): reducción menor al 10 %.

Los colores solo se aplican cuando la salida es una terminal interactiva. Define `NO_COLOR=1` para desactivarlos.

## HEIC/HEIF de iPhone

Los HEIC/HEIF de iPhone se decodifican con el primer backend disponible:

1. ImageMagick, si tiene soporte HEIC.
2. `sips`, disponible en macOS.
3. `heif-convert`, disponible en Linux con el paquete `libheif`.

Si no hay ningún backend disponible, el script muestra un error y no modifica el archivo original.

## Dependencias

- `magick` (ImageMagick 7).
- `exiftool`.
- `jpegoptim`, necesario solo al generar JPG.
- Opcionalmente, soporte HEIC en ImageMagick, `sips` o `heif-convert`.

En macOS se pueden instalar las dependencias con MacPorts:

```sh
sudo port install ImageMagick7 exiftool jpegoptim
```
