#capitulo(title: "Implementación de la solución")[

    //intro

#capitulo(title: "Introducción")[

La gestión de los recursos hídricos en zonas urbanas y periurbanas requiere herramientas de modelación capaces de representar la complejidad del territorio. Modelos hidrológicos distribuidos, como PUMMA (Peri-Urban Model for landscape MAnagement) @Jankowfsky10, basan su análisis en Unidades de Respuesta Hidrológica (URHs) @Flugel95. Estas unidades deben cumplir con requisitos geométricos, como la convexidad y ciertos parámetros de forma, para asegurar condiciones adecuadas para la simulación. En este contexto, la generación automatizada de mallas poligonales a partir de información geográfica es un desafío que combina la ingeniería en computación con la ingeniería hidráulica.

El origen de este trabajo se sitúa en la tesis de magíster de Pedro Sanzana @Sanzana11, donde se identificó que las URHs utilizadas en modelos distribuidos debían cumplir con criterios estrictos de forma, convexidad y orientación para evitar inestabilidades numéricas en las simulaciones. A partir de esos requerimientos, Sergio Villarroel @Villarroel23 desarrolló un plugin para QGIS que automatizaba la triangulación de polígonos y su posterior disolución con base en dichos criterios geométricos. Aunque ese plugin validó la factibilidad del proceso, presentaba problemas de estabilidad que provocaban cierres inesperados del software al trabajar con geometrías complejas.

Este trabajo aborda el problema de generar mallas poligonales controlando parámetros de calidad geométrica, utilizando QGIS como plataforma central. Se seleccionó esta herramienta por ser de código abierto y contar con una comunidad activa que aporta soporte y funcionalidades. El desarrollo de plugins en QGIS se realiza mediante Python, lo que otorga flexibilidad para extender el software. Sin embargo, la ejecución de código externo dentro de este ambiente presenta desafíos técnicos: la integración directa de librerías de triangulación ha generado inestabilidad, conflictos de memoria y cierres inesperados (crashes), impidiendo la automatización confiable del proceso en versiones anteriores.

Se propone abordar estas problemáticas mediante ingeniería de software e integración de algoritmos. En particular, se plantea incorporar el algoritmo Polylla @Salinas22, originalmente escrito en C++, al entorno de Python y posteriormente a QGIS. Polylla genera mallas poligonales a partir de triangulaciones arbitrarias sin introducir puntos adicionales al dominio, lo que permite mantener la fidelidad de los datos topográficos de entrada. Para ello, se propone desarrollar un binding que exporte las funcionalidades de Polylla como una librería nativa de Python. Tomando como base el trabajo de Villarroel @Villarroel23, se diseñará una nueva versión del plugin que permita generar mallas ajustando parámetros relevantes del proceso, y que rediseñe el flujo de triangulación para mejorar la estabilidad, desacoplando etapas del proceso para reducir fallos en el entorno de QGIS. El resultado esperado es una herramienta modular orientada a apoyar la preparación de datos para el modelamiento hidrológico.

== Objetivos

=== Objetivo General

Diseñar e implementar una herramienta de software integrada en QGIS que permita la generación de mallas poligonales mediante la utilización del algoritmo Polylla, asegurando estabilidad operativa y corrigiendo los problemas presentes en versiones anteriores, con control de parámetros relevantes del proceso.

=== Objetivos Específicos

+ *Desarrollar un binding de Python para Polylla*: Crear una interfaz funcional entre el
  código original en C++ de Polylla y Python, permitiendo su uso como librería estándar
  dentro del ecosistema de desarrollo actual.

+ *Rediseñar la arquitectura de triangulación*: Implementar un mecanismo de ejecución
  externa para el proceso de triangulación que evite los conflictos de memoria y crashes
  aleatorios observados al utilizar la librería Triangle directamente dentro del entorno
  de QGIS.

+ *Desarrollar un nuevo plugin para QGIS*: Integrar la nueva librería de Polylla y el
  flujo de triangulación corregido en un complemento de usuario final, permitiendo la
  manipulación de capas vectoriales y la configuración de parámetros.

+ *Demostrar el funcionamiento de la solución*: Ejecutar el flujo completo (triangulación
  y Polylla) en casos representativos dentro de QGIS, generando y visualizando las capas
  resultantes. La validación cuantitativa y la comparación con herramientas previas se
  dejan como trabajo futuro.

== Estructura del documento

El capítulo 2 (Situación Actual) revisa los antecedentes de este trabajo: la tesis de
Sanzana, el plugin de Villarroel, el algoritmo Polylla y las tecnologías involucradas,
cerrando con la justificación de la propuesta frente a las limitaciones observadas. El
capítulo 3 (Implementación) detalla la creación del binding, la arquitectura del plugin y
las decisiones adoptadas para resolver los problemas de estabilidad en la triangulación.
El capítulo 4 (Resultados) presenta casos demostrativos del flujo completo ejecutado en
QGIS, mostrando la triangulación y la aplicación de Polylla sobre distintas geometrías.
Finalmente, el capítulo 5 expone las conclusiones del trabajo y las líneas de desarrollo
que quedan abiertas, entre ellas una evaluación cuantitativa más completa de la calidad
geométrica de las mallas.

]

    //-----

== Requerimientos de la solución

El plugin debe permitir ejecutar un flujo de dos etapas: primero la triangulación de una capa poligonal de entrada, con parámetros de calidad configurables (ángulo mínimo y área máxima), y luego la generación de una malla poligonal mediante Polylla sobre la triangulación resultante. Ambas etapas pueden ejecutarse de forma independiente o secuencial.

Más allá de la funcionalidad, dos restricciones condicionaron las decisiones de implementación. La primera es la estabilidad: la ejecución de la triangulación no debe cerrar QGIS de forma abrupta ante geometrías complejas o fallos de la librería. La segunda es el aislamiento de fallos: si una etapa falla, el error debe quedar contenido y reportarse al usuario sin afectar el proceso principal del SIG. Estas dos restricciones son las que motivaron la arquitectura descrita en la sección siguiente.

== Arquitectura general de la solución

La solución se organiza en dos etapas con mecanismos de ejecución distintos. La triangulación se ejecuta como subproceso externo al proceso principal de QGIS, de modo que cualquier fallo quede contenido y no produzca un cierre inesperado del SIG. Polylla, en cambio, se ejecuta dentro del entorno Python de QGIS mediante el binding desarrollado, como una tarea asíncrona que no bloquea la interfaz.

=== Componentes

// [acá irá la figura de arquitectura]

La solución se compone de tres elementos:

+ *Interfaces de usuario (Qt Designer):* dos diálogos independientes, uno para la triangulación y otro para Polylla, que exponen los parámetros configurables y gestionan la interacción con el usuario.

+ *Núcleo del plugin (Python, PyQGIS):* implementa la lógica de control del flujo en los módulos `triangulation_dialog.py` y `polylla_integration.py`. Sus responsabilidades incluyen validar entradas, preparar directorios de trabajo, construir y lanzar el subproceso de triangulación, y transformar los resultados en capas QGIS.

+ *Librería Polylla para Python (`py_polylla`):* módulo compilado que expone el algoritmo Polylla al entorno Python. El plugin lo invoca para construir la malla poligonal a partir de la triangulación.

=== Flujo de ejecución

El flujo comienza con la selección de una capa vectorial poligonal en QGIS y la configuración de parámetros de triangulación. El plugin valida la entrada y lanza el script `triangulation.py` como subproceso, pasándole los parámetros configurados. El resultado se escribe en disco como un Shapefile de triángulos, lo que deja un producto intermedio persistente que puede inspeccionarse o reutilizarse sin repetir la ejecución completa.

Una vez disponible la capa triangulada, el usuario puede ejecutar Polylla desde el segundo diálogo. El plugin convierte la capa al formato `OFF`, ejecuta Polylla mediante `py_polylla` dentro de una `QgsTask` y carga el resultado como una nueva capa en memoria en el proyecto de QGIS.

// - - - - - - - - - - - - - - - - - - - - - - - - 

=== Binding: Creación de py_polylla

Para habilitar el uso de Polylla desde Python se implementó un módulo con `pybind11`, que se llamó `py_polylla`. Este módulo expone una interfaz acotada, centrada en la configuración del algoritmo y en su ejecución a partir de archivos de triangulación.

El binding expone dos elementos principales:

+ *PolyllaOptions:* se expone como clase Python con sus campos configurables mediante `def_readwrite`. Los atributos expuestos corresponden a `smooth_method`, `smooth_iterations` y `target_length`, consistentes con la estructura declarada en `polylla.hpp`.

+ *Polylla:* se expone como clase Python con constructores que reciben rutas a archivos y una instancia opcional de `PolyllaOptions`. En el plugin se utiliza el constructor que recibe archivos en formato `OFF`.

Para construir el módulo se utilizó `CMake` junto con `pybind11`. El archivo `CMakeLists.txt` localiza el entorno de Python para obtener sus headers y librerías, incorpora `pybind11` como dependencia y compila el wrapper como una biblioteca compartida importable desde Python.

=== Construcción de la representación OFF

A partir de la capa triangulada, el plugin construye la representación de entrada para Polylla en formato `OFF` mediante la función `build_off_from_layer`. Esta función recorre los triángulos de la capa y genera dos estructuras: un arreglo de vértices y un arreglo de caras, donde cada cara es una terna de índices hacia el arreglo de vértices. Dado que vértices adyacentes entre triángulos aparecen duplicados en la representación de la capa, se aplica una deduplicación basada en redondeo de coordenadas: los valores (x, y) se cuantizan a una cantidad fija de decimales antes de registrar cada vértice en el índice global, de modo que puntos coincidentes queden mapeados a una misma entrada.


// - - - - - - - - - - - - - - - - - - - - - - - - 


== Requerimientos de la solución

En esta sección se establecen los requerimientos que guiaron la implementación del plugin y las decisiones adoptadas. Estos requerimientos se definieron a partir de los objetivos del trabajo y de los problemas observados en la solución previa, principalmente en lo relativo a estabilidad durante la triangulación e integración de un algoritmo externo (Polylla) en el entorno de QGIS.

=== Requisitos funcionales

Los requisitos funcionales describen las acciones que el usuario debe poder realizar mediante el plugin y los resultados esperados en cada etapa. En este trabajo, el flujo se compone de una etapa de triangulación y una etapa de generación de malla poligonal mediante Polylla, con la posibilidad de ejecutar ambas de forma secuencial.

La herramienta debe permitir lo siguiente:

- Seleccionar una capa vectorial poligonal en QGIS como entrada para el proceso de malla.
- Ejecutar la triangulación de la geometría de entrada, configurando al menos ángulo mínimo y área máxima.
- Definir un directorio o ruta de salida para los archivos generados por la triangulación (por ejemplo, en formato SHP).
- Seleccionar una capa triangulada como entrada para la ejecución de Polylla.
- Aplicar Polylla sobre la triangulación seleccionada y generar como salida una malla poligonal como capa en memoria dentro de QGIS.
- Ejecutar el flujo completo de forma secuencial: triangulación y luego Polylla.

=== Requisitos no funcionales

Los requisitos no funcionales establecen restricciones y propiedades del sistema asociadas al uso dentro de QGIS. Estos criterios son relevantes debido a que el trabajo se ejecuta en un entorno con un proceso principal que puede terminar en un _crash_ si ocurre una falla de bibliotecas externas, y donde los tiempos de ejecución y la claridad de la interfaz influyen directamente en la utilidad práctica del plugin.

- Estabilidad: la ejecución de la triangulación no debe cerrar QGIS de forma abrupta al fallar, incluso ante geometrías no convexas o entradas complejas.
- Aislamiento de fallos: si una etapa falla (triangulación o Polylla), el sistema debe terminar la ejecución de forma controlada y reportar el error al usuario.
- Reproducibilidad: dado un mismo input y parámetros, el sistema debe producir resultados consistentes.
- Mantenibilidad: el código debe quedar separado por componentes (triangulación y Polylla) para facilitar cambios y depuración.
- Usabilidad: los parámetros principales deben estar disponibles en la interfaz, con valores por defecto razonables y validación de rangos.
- Rendimiento: el tiempo de ejecución debe ser razonable para tamaños de entrada típicos.

== Arquitectura general de la solución

En este apartado se describe la arquitectura general del plugin y el flujo de ejecución completo, desde la selección de una capa en QGIS hasta la generación de la malla poligonal final. La arquitectura se diseñó para responder a dos restricciones principales: por un lado, la necesidad de controlar parámetros de calidad durante la triangulación y, por otro, evitar cierres inesperados de QGIS asociados a la ejecución de rutinas de triangulación dentro del mismo proceso del SIG. Para ello, la solución se organiza en dos etapas, donde la triangulación se ejecuta como subproceso externo y Polylla se ejecuta dentro del entorno Python de QGIS utilizando el binding desarrollado. 


=== Flujo de ejecución

El flujo de trabajo comienza con la selección de una capa vectorial poligonal desde QGIS. Esta capa constituye la entrada geométrica del proceso, junto con los parámetros de triangulación definidos por el usuario (ángulo mínimo y área máxima). El plugin valida la existencia de una capa seleccionada, la presencia de geometrías y la coherencia de los parámetros numéricos.

La etapa de triangulación se ejecuta como un subproceso independiente del sistema. El plugin define un directorio de trabajo y ejecuta el script asociado a la triangulación, entregando los parámetros configurados por el usuario. El resultado de esta etapa se materializa como archivos en disco en formato Shapefile (SHP), que representan la triangulación generada. Esta decisión permite que si ocurre un fallo durante la triangulación, el error quede contenido en el subproceso y no en el proceso principal de QGIS. Además, deja un resultado intermedio persistente que puede inspeccionarse o reutilizarse sin repetir la ejecución completa.

En la etapa siguiente, Polylla opera sobre la triangulación ya generada. El plugin carga una capa triangulada en QGIS y ejecuta Polylla utilizando la librería de Python creada a partir del binding C++/Python. El resultado final corresponde a una malla poligonal que se entrega como una nueva capa en memoria, agregada al proyecto de QGIS para su visualización y uso posterior.

=== Componentes

La solución se compone de los siguientes elementos:
+ Interfaces de usuario en QGIS: la interfaz de triangulación permite seleccionar la capa de entrada, configurar parámetros y definir rutas de salida para los productos de la triangulación, mientras que la interfaz de Polylla permite seleccionar una capa de entrada y el nombre de la capa de salida.

+ Núcleo del plugin (Python, PyQGIS): implementa la lógica de control del flujo. Sus responsabilidades incluyen validar entradas, preparar directorios, construir comandos de ejecución, manejar archivos intermedios y transformar resultados en capas QGIS.


+ Librería Polylla para Python (binding): trae el código C++ de Polylla al entorno Python. El plugin invoca esta librería para construir la malla poligonal a partir de la triangulación.

== Integración de Polylla

El algoritmo Polylla fue desarrollado originalmente en C++ y su uso dentro de QGIS requiere una interfaz hacia Python, dado que los plugins de QGIS se implementan en PyQGIS. En esta sección se describe el código base reutilizado, el diseño del binding implementado con pybind11, el proceso de construcción del módulo mediante CMake y la API final disponible desde Python.

=== Descripción del código base

La implementación original de Polylla se reutiliza como base sin modificar su lógica principal. El núcleo del algoritmo se encuentra definido en polylla.hpp, donde se declara la estructura PolyllaOptions para configurar aspectos del algoritmo y la clase Polylla, responsable de ejecutar el proceso de generación de mallas poligonales a partir de una triangulación.

Polylla opera sobre una representación de malla triangulada basada en estructuras topológicas, apoyándose en triangulation.hpp y componentes relacionados. Este enfoque permite recorrer adyacencias y relaciones entre elementos, lo cual es necesario para construir regiones y fusionar triángulos. En el código base también se incorpora la medida m_edge_ratio mediante m_edge_ratio.hpp, utilizada por Polylla para evaluar calidad o suavizado de las mallas resultantes.

Desde el punto de vista de entradas, el proyecto original contempla la construcción de Polylla a partir de archivos externos, incluyendo formatos como `OFF` y el conjunto de archivos .node, .ele y .neigh, que son extensiones comunes de triangulaciones generadas por triangle. Desde el punto de vista de salidas, la implementación original permite exportar resultados en distintos formatos mediante métodos que escriben archivos, pero para los fines del plugin se utilizó la exportación en formato `OFF` para representar la malla poligonal resultante.

=== Binding: Creación de py_polylla

Para habilitar el uso de Polylla desde Python se implementó un módulo con `pybind11`, que se llamó `py_polylla`. Este módulo expone una interfaz acotada, centrada en la configuración del algoritmo y en su ejecución a partir de archivos de triangulación.

El binding expone dos elementos principales:
+ PolyllaOptions: se expone como clase `Python` con sus campos configurables mediante `def_readwrite`. Los atributos expuestos corresponden a `smooth_method`, `smooth_iterations` y `target_length`, consistentes con la estructura declarada en `polylla.hpp`. Esto nos permite configurar el comportamiento del algoritmo.


+ Polylla: se expone como clase `Python` con constructores que reciben rutas a archivos y una instancia opcional de `PolyllaOptions`. Se hara uso del contructor de archivos en formato `OFF`.

Finalmente, para construir el módulo `py_polylla` se utilizó `CMake` como sistema de compilación, junto con `pybind11`. En términos generales, el archivo `CMakeLists.txt` localiza el entorno de Python para obtener sus headers y librerías, incorpora `pybind11` como dependencia y compila el archivo del wrapper como una biblioteca. El resultado es un artefacto importable desde Python, que luego puede ser utilizado desde el entorno de QGIS como una librería nativa.

== Triangulación

La triangulación se implementa como un script externo (triangulation.py) que recibe una capa poligonal en formato SHP, aplica triangulación con restricciones de calidad y genera como salida un nuevo Shapefile compuesto por triángulos. Este componente se diseñó como una pieza independiente del entorno de QGIS, de manera que pueda ejecutarse como subproceso y dejar sus resultados en disco para su posterior uso por el resto del flujo.

=== Algoritmo de triangulación

La triangulación se realiza utilizando la librería triangle. El script transforma las geometrías de entrada, manejadas como objetos Polygon o MultiPolygon de Shapely, a una representación adecuada para la librería de triangulación. Para ello se construyen segmentos que representan el contorno exterior y los contornos interiores (agujeros) del polígono, junto con puntos auxiliares para indicar regiones internas no triangulables.

El script incluye funciones auxiliares para esta preparación. build_simple_segments construye los segmentos cerrados de cada anillo a partir de sus vértices. polygon_centroid calcula un punto representativo para cada anillo interior, usado como punto dentro del agujero, lo que permite a la triangulación respetar vacíos internos. Posteriormente, triangulate_single_polygon ejecuta la triangulación sobre un polígono individual y devuelve una colección de triángulos representados nuevamente como polígonos.


=== Parametros de calidad

El script soporta parámetros de calidad asociados a la triangulación mediante argumentos de línea de comandos. Los parámetros principales son:

- Ángulo mínimo (`--min-angle`): permite imponer una cota inferior sobre los ángulos internos de los triángulos, lo que reduce la generación de triángulos delgados.


- Área máxima (`--max-area`): permite imponer un límite superior al área de los triángulos, controlando el nivel de refinamiento de la malla.

=== Manejo de entradas y salidas
La ejecución del componente se realiza a través de un punto de entrada estándar (main) que parsea argumentos con `argparse`. El script requiere explícitamente dos rutas:

- Entrada (`--in`): ruta al Shapefile de polígonos a triangular.


- Salida (`--out`): ruta donde se guardará el Shapefile resultante de triángulos.

El proceso de lectura y escritura utiliza fiona para operar sobre Shapefiles y Shapely para convertir cada feature a geometría manipulable (shape). El flujo considera que la entrada puede contener geometrías Polygon y MultiPolygon, lo que permite procesar capas donde existan unidades compuestas por múltiples partes. Para cada polígono se genera una colección de triángulos, y estos se escriben como nuevos polígonos en el archivo de salida.

== Polylla en QGIS

Polylla se ejecuta dentro del plugin como una etapa posterior a la triangulación. Su propósito es tomar una capa triangulada, convertirla a un formato de entrada compatible con el binding (`OFF`), ejecutar Polylla desde Python mediante el módulo py_polylla y transformar el resultado nuevamente a una capa que QGIS pueda cargar. Esta integración se implementa en el archivo `polylla_integration.py`.

=== Entradas requeridas
La entrada de Polylla es una capa que contiene la triangulación generada en la etapa anterior. En términos de estructura, el flujo asume que la capa de entrada:

- Está compuesta por features poligonales que representan triángulos.

- Cada triángulo se define por tres vértices, con el primer punto repetido al final (anillo cerrado).

- Comparte un sistema de referencia (CRS).

A partir de esta capa triangulada, el plugin construye la representación necesaria para Polylla en formato `OFF`. Esto se realiza mediante la función `build_off_from_layer`, que recorre los triángulos y genera dos estructuras: un arreglo de vértices y un arreglo de caras, donde cada cara es una terna de índices hacia el arreglo de vértices. Para evitar duplicación de vértices que representan el mismo punto, se aplica una estrategia de deduplicación basada en redondeo de coordenadas, que cuantiza los valores (x, y) a una cantidad fija de decimales antes de registrar un vértice global.

=== Ejecución de Polylla

El puente principal de ejecución se implementa en run_polylla_off. Este método recibe como entrada un archivo OFF temporal (generado desde la capa triangulada). Con esto se construye una instancia de PolyllaOptions y se ejecuta Polylla sobre el archivo OFF de entrada. La salida se produce como un nuevo archivo OFF, que representa la malla poligonal resultante.

La ejecución completa se encapsula dentro de una tarea (PolyllaTask) basada en QgsTask. Esto permite que el proceso se ejecute sin bloquear la interfaz de QGIS y proporciona un punto de control para manejar errores y estados. El método run de la tarea define el flujo completo:

+ Construir la representación OFF desde la capa triangulada.


+ Escribir el OFF a un archivo temporal.


+ Ejecutar Polylla y producir un OFF de salida.


+ Leer el OFF resultante y convertirlo a una capa en memoria.

== Interfaz de usuario

La interfaz se diseñó usando Qt Designer, lo que permite mantener la definición visual en archivos .ui y cargarla desde Python. El plugin separa la interacción del usuario en dos diálogos, alineados con las etapas del flujo.

=== Diálogo de triangulación

El diálogo de triangulación permite seleccionar una capa poligonal del proyecto y configurar parámetros básicos de calidad. Incluye:

- Selector de capa de entrada (capas vectoriales poligonales).

- Parámetros: ángulo mínimo y área máxima.

- Parámetros asociados a descriptor de forma y umbral (presentes en la interfaz, con habilitación condicional del umbral).


- Selección de directorio de salida mediante un selector de archivos.

- Botones de ejecución y cancelación.

La triangulación se ejecuta invocando el script triangulation.py como subproceso, pasando los parámetros seleccionados y construyendo la ruta de salida en base al nombre de la capa.

#figure(
        image("imagenes/triangulation.png", width: 60%),
        caption: "Ventana de diálogo para la triangulación de una capa poligonal.",
    )

=== Diálogo de Polylla

El diálogo de Polylla permite seleccionar la capa triangulada (capas poligonales) y configurar parámetros de suavizado:

- Capa de entrada.

- Método de suavizado: None, Laplacian Edge-Ratio, Laplacian, Distmesh.

- Número de iteraciones.

Este diálogo valida que exista una capa seleccionada antes de permitir la ejecución.

#figure(
        image("imagenes/polylla.png", width: 50%),
        caption: "Ventana de díalogo para la aplicación de Polylla sobre una capa triangulada.",
    )

== Alternativas descartadas

Durante el desarrollo se evaluaron alternativas para resolver la etapa de triangulación y su ejecución dentro de QGIS. A continuación se resumen los intentos realizados y las razones para descartarlos.

=== Triangulación con Scipy

Se probó realizar la triangulación usando SciPy con el objetivo de descartar que la librería triangle fuera la causa principal de los cierres inesperados de QGIS. Sin embargo, esta alternativa resultó limitada para el caso de uso del plugin, ya que no permitía controlar parámetros de calidad relevantes, como ángulo mínimo o área máxima. Esto impedía replicar el comportamiento requerido para generar mallas con restricciones y reducía la utilidad de la triangulación dentro del flujo.

=== Ejecución en QGIS con QProcess

Se exploró el uso de QProcess para ejecutar la triangulación como proceso externo desde QGIS. La intención era desacoplar la ejecución del proceso principal y mantener integración con la interfaz. En la práctica, la llamada no lograba ejecutarse correctamente fuera del ambiente esperado, perdiendo contexto y fallando durante la invocación del proceso.

=== Decisiones finales

Frente a estas limitaciones, se optó por ejecutar la triangulación mediante una llamada a sistema nativa de Python. Esta alternativa permitió completar la triangulación y generar los archivos de salida de forma consistente. Como consecuencia, la ejecución puede congelar la interfaz de QGIS durante el tiempo que dura el subproceso, pero se privilegió contar con una solución funcional, manteniendo los parámetros de calidad y evitando las restricciones observadas en SciPy y QProcess.

]