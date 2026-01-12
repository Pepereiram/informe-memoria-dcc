#import "final.typ": conf, resumen, dedicatoria, agradecimientos, start-doc, end-doc, capitulo, apendice
#import "metadata.typ": example-metadata

#show: conf.with(metadata: example-metadata)

#resumen(metadata: example-metadata)[
    #lorem(150)
    
    #lorem(100)
    
    #lorem(100)
]

#dedicatoria[
    Dedicado a mi abuelo, Raúl.
]

#agradecimientos[
    #lorem(150)
    
    #lorem(100)
    
    #lorem(100)
]

#show: start-doc

#capitulo(title: "Introducción")[

La gestión eficiente de los recursos hídricos en zonas urbanas y periurbanas requiere herramientas de modelación avanzadas capaces de representar la complejidad del territorio. Modelos hidrológicos distribuidos, como PUMMA (Peri-Urban Model for landscape MAnagment) [...], basan su análisis en Unidades de Respuesta Hidrológica (URHs). Estas unidades deben cumplir con estrictos requisitos geométricos, como la convexidad y ciertos parámetros de forma, para garantizar la precisión de las simulaciones. En este contexto, la generación automatizada de estas mallas poligonales a partir de información geográfica es un desafío que combina la ingeniería en computación con la ingeniería hidráulica.

Este trabajo aborda el problema de generar mallas poligonales de alta calidad geométrica utilizando QGIS como plataforma central. Se seleccionó esta herramienta por ser de código abierto y contar con una activa comunidad que aporta soporte y funcionalidades. Además, el desarrollo de plugins en QGIS se realiza mediante Python, lo que otorga gran flexibilidad. Sin embargo, la ejecución de código externo dentro de este ambiente presenta desafíos técnicos. Específicamente, la integración directa de librerías de triangulación ha generado inestabilidad, conflictos de memoria y cierres inesperados (crashes), impidiendo la automatización confiable del proceso en versiones anteriores.

El presente trabajo busca resolver estas problemáticas mediante la ingeniería de software y la implementación de nuevos algoritmos. Se propone la integración del algoritmo Polylla [...], originalmente escrito en C++, al entorno de Python y posteriormente a QGIS. Para ello, se desarrolló un binding que exporta las funcionalidades de Polylla como una librería nativa de Python. Utilizando esta librería y tomando como base el trabajo previo de Sergio Villarroel [...], se diseñó una nueva versión del plugin. Esta versión permite generar mallas controlando sus parámetros de calidad y rediseña el flujo de triangulación para asegurar la estabilidad, desacoplando procesos críticos para evitar fallos en el entorno de QGIS. De esta forma, se entrega una herramienta modular y robusta que facilita la preparación de datos para el modelamiento hidrológico.

Finalmente, el informe se estructura de la siguiente manera: en la Situación Actual se revisan los antecedentes teóricos, las herramientas previas y el algoritmo Polylla. La sección de Implementación detalla la creación del binding, la arquitectura del plugin y la solución a los problemas de estabilidad. Posteriormente, en Resultados y Discusión, se presentan las pruebas de funcionamiento y la validación de las mallas generadas, cerrando con las Conclusiones y líneas de trabajo futuro.

== Objevitos
=== Objetivo General

Diseñar e implementar una herramienta de software integrada en QGIS que permita la generación de mallas poligonales de alta calidad mediante la utilización del algoritmo Polylla, asegurando la estabilidad operativa y la corrección de errores críticos presentes en versiones anteriores.

=== Objetivos Específicos

+ *Desarrollar un binding de Python para Polylla*: Crear una interfaz funcional entre el código original en C++ de Polylla y Python, permitiendo su uso como una librería estándar dentro del ecosistema de desarrollo actual.
+ *Rediseñar la arquitectura de triangulación*: Implementar un mecanismo de ejecución externa para el proceso de triangulación que evite los conflictos de memoria y crashes aleatorios observados al utilizar la librería Triangle directamente dentro del entorno de QGIS.
+ *Desarrollar un nuevo plugin para QGIS*: Integrar la nueva librería de Polylla y el flujo de triangulación corregido en un complemento de usuario final, permitiendo la manipulación de capas vectoriales y la configuración de parámetros.
+ *Validar y comparar la solución*: Evaluar la calidad de las mallas generadas en contraste con las herramientas previas.

]

#capitulo(title: "Situación Actual")[
    
Este trabajo de título es la intersección de dos líneas de desarrollo previas: por un lado, la necesidad de preprocesamiento geométrico para la hidrología urbana (Sanzana y Villarroel) y, por otro, la optimización algorítmica de mallas poligonales (Salinas). A continuación, se describen los antecedentes, el marco teórico y las tecnologías involucradas.

== Antecedentes en QGIS

El origen de la necesidad geométrica abordada en esta memoria parte de la tesis de magíster de Pedro Sanzana [...]. Su trabajo se centró en la caracterización y modelamiento de procesos hidrológicos en cuencas periurbanas del piedemonte de Santiago. Para utilizar modelos distribuidos como PUMMA, Sanzana estableció que el análisis espacial requería mallas base compuestas por polígonos irregulares (URHs). Sin embargo, identificó que estas unidades debían cumplir con criterios estrictos de forma, convexidad y orientación para evitar inestabilidades numéricas en las simulaciones hídricas.

Posteriormente, Sergio Villarroel [...] retomó estos requerimientos con el objetivo de automatizar el proceso dentro de un Sistema de Información Geográfica (GIS). Villarroel desarrolló un plugin para QGIS capaz de triangular polígonos y disolverlos basándose en criterios de forma y convexidad planteados por Sanzana. Aunque este plugin validó la factibilidad de la automatización, presenta problemas de estabilidad, ocasionando el cierre del programa y la pérdida del progreso.

== Algoritmo Polylla

Paralelamente a lo anterior, Sergio Salinas [...] propuso el algoritmo Polylla. Este algoritmo, implementado originalmente en C++, ofrece una estrategia robusta para generar mallas poligonales a partir de triangulaciones arbitrarias.

El funcionamiento de Polylla se basa en el concepto de regiones de arista terminal (terminal-edge regions). En lugar de procesar polígonos de forma aislada, el algoritmo agrupa triángulos adyacentes basándose en la longitud de sus aristas. El proceso consta de tres fases principales:

+ *Etiquetado*: Se clasifican las aristas de la triangulación (como frontera, interna o terminal) según su longitud relativa en los triángulos que las comparten.
+ *Recorrido*: Se construyen los polígonos fusionando los triángulos que pertenecen a una misma región, utilizando las aristas etiquetadas como guía.
+ *Reparación*: Se detectan polígonos "no simples" (que no sean simplemente conexos) y se dividen para asegurar que la malla final sea válida geométricamente.

La principal ventaja de Polylla frente a métodos clásicos, como los diagramas de Voronoi [...], radica en su capacidad para generar mallas con menos polígonos y, fundamentalmente, sin insertar puntos adicionales al dominio. Esto asegura que la malla resultante respete exactamente los vértices de la entrada original, una característica crítica para mantener la fidelidad de los datos topográficos. Además, su estructura de datos basada en Half-Edge permite una manipulación eficiente de la topología.

== Tecnologías y herramientas

=== QGIS

QGIS es la plataforma de referencia en sistemas de información geográfica de código abierto [...]. Su arquitectura permite la extensión de funcionalidades mediante plugins escritos en Python (PyQGIS). Este entorno ofrece acceso a librerías geoespaciales como GDAL/OGR, pero impone restricciones en la gestión de memoria y subprocesos, lo que es crítico para la estabilidad de algoritmos computacionalmente intensivos.

=== Triangle

Para la etapa de triangulación, el estándar de facto en la investigación académica es la librería Triangle, desarrollada por J.R. Shewchuk [...]. Esta librería permite generar triangulaciones de Delaunay con restricciones de calidad (ángulos mínimos, áreas máximas).

=== Pybind11

Dado que Polylla está escrito en `C++` por razones de rendimiento y el ecosistema de QGIS opera en `Python`, es necesario integrar ambos lenguajes. Tecnologías como pybind11 permiten crear bindings que exponen funciones y clases de `C++` a `Python`, manteniendo la eficiencia del código compilado.

== Limitaciones de la solución actual

El plugin desarrollado previamente por Villarroel sufre de inestabilidad ("crashes") al ejecutarse sobre geometrías complejas o mallas de gran tamaño.

El diagnóstico realizado sugiere que el problema radicaba en la invocación directa de la librería Triangle dentro del mismo espacio de memoria del proceso principal de QGIS. Al producirse errores de segmentación o manejo de excepciones no controladas dentro de la rutina de triangulación, QGIS se cerraba abruptamente, provocando la pérdida de trabajo del usuario.

== Justificación de la propuesta

Ante el escenario descrito, surge la necesidad de rediseñar la solución tecnológica existente. El plugin anterior dependía de métodos de disolución que no siempre garantizaban una solución geométrica adecuada en una sola iteración y presentaba problemas de estabilidad al trabajar con geometrías complejas. Estas limitaciones afectan directamente la calidad de las mallas utilizadas en la modelación hidrológica y la confiabilidad de la herramienta desde el punto de vista del usuario.

La creación del nuevo plugin se justifica, en primer lugar, por una mejora en la robustez algorítmica. La integración de Polylla reemplaza la lógica de disolución anterior por un algoritmo determinista. Esto permite generar mallas con menos polígonos, sin incorporar vértices artificiales que puedan alterar la representación del dominio y, con ello, el comportamiento del modelo hidrológico.

En segundo lugar, la propuesta apunta a mejorar la estabilidad del software. La estrategia adoptada consiste en desacoplar el proceso de triangulación del ambiente de QGIS, ejecutándolo como un subproceso independiente del sistema.


]

#capitulo(title: "Implementación de la solución")[
== Requerimientos de la solución

En esta sección se establecen los requerimientos que guiaron la implementación del plugin y las decisiones adoptadas. Estos requerimientos se definieron a partir de los objetivos del trabajo y de los problemas observados en la solución previa, principalmente en lo relativo a estabilidad durante la triangulación e integración de un algoritmo externo (Polylla) en el entorno de QGIS.

=== Requisitos funcionales

Los requisitos funcionales describen las acciones que el usuario debe poder realizar mediante el plugin y los resultados esperados en cada etapa. En este trabajo, el flujo se compone de una etapa de triangulación y una etapa de generación de malla poligonal mediante Polylla, con la posibilidad de ejecutar ambas de forma secuencial.

La herramienta debe permitir lo siguiente:

- Seleccionar una capa vectorial poligonal en QGIS como entrada para el proceso de malla.

- Ejecutar la triangulación de la geometría de entrada, configurando al menos ángulo mínimo y área máxima.

- Definir rutas de salida de archivos que se crean a partir de una triangulación.

- Aplicar Polylla sobre una triangulación previamente generada.


La herramienta debe generar como salida una malla poligonal (capa) derivada de Polylla.


La herramienta debe permitir ejecutar el flujo completo de forma secuencial: triangulación y luego Polylla.

=== Requisitos no funcionales

Los requisitos no funcionales establecen restricciones y propiedades del sistema asociadas al uso dentro de QGIS. Estos criterios son relevantes debido a que el trabajo se ejecuta en un entorno con un proceso principal que puede terminar en un _crash_ si llega a haber una falla de bibliotecas externas, y donde los tiempos de ejecución y la claridad de la interfaz influyen directamente en la utilidad práctica del plugin.

- Estabilidad: la ejecución de la triangulación no debe cerrar QGIS de forma abrupta al fallar, incluso ante geometrías no conexas o entradas complejas.

- Reproducibilidad: dado un mismo input y parámetros, el sistema debe producir resultados consistentes.

- Mantenibilidad: el código debe quedar separado por componentes (triangulación y Polylla) para facilitar cambios y depuración.

- Usabilidad: los parámetros principales deben estar disponibles en la interfaz, con valores por defecto razonables y validación de rangos.

- Rendimiento: el tiempo de ejecución debe ser razonable para tamaños de entrada típicos.

== Arquitectura general de la solución

En este apartado se describe la arquitectura general del plugin y el flujo de ejecución completo, desde la selección de una capa en QGIS hasta la generación de la malla poligonal final. La arquitectura se diseñó para responder a dos restricciones principales: por un lado, la necesidad de controlar parámetros de calidad durante la triangulación y, por otro, evitar cierres inesperados de QGIS asociados a la ejecución de rutinas de triangulación dentro del mismo proceso del SIG. Para ello, la solución se organiza en dos etapas, donde la triangulación se ejecuta como subproceso externo y Polylla se ejecuta dentro del entorno Python de QGIS utilizando el binding desarrollado. 

INSERTAR FIGURA AQUI??

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

AGREGAR FIGURA???

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

#capitulo(title: "Resultados y discusión")[

== Casos de prueba
]

#capitulo(title: "Conclusión")[
    #lorem(100)
    
    #lorem(100)
    
    #lorem(100)
]

#show: end-doc

#apendice(title: "Anexo")[
    #lorem(100)
    
    #lorem(100)
    
    #lorem(100)

    @CorlessJK97 @Turing38

    #figure(
        image("imagenes/institucion/fcfm.svg", width: 20%),
        caption: "Logo de la facultad",
    )

    #figure(
        table(
            columns: 3,
            "Campo 1", "Campo 2", "Num",
            "Valor 1a", "Valor 2a", "3",
            "Valor 1b", "Valor 2b", "3",
        ),
        caption: "Tabla 1",
    )

#box(
  inset: (top: 10pt, bottom: 10pt, left: 12pt, right: 12pt),
  stroke: 1pt,
  radius: 0pt,
)[
  *Algoritmo 1: Triangulación con Triangle* \

  #line(length: 100%, stroke: 1pt)

  *Datos:* Capa de polígonos (Polygon / MultiPolygon), `min_angle`, `max_area` \
  *Resultado:* Triángulos (polígonos) exportables a SHP \

  `triangulosAAgregar <- []` \
  `para cada feat en CapaPoligonos hacer` \
  `  geom <- feat.getGeometry()` \
  `  si geom no es Polygon ni MultiPolygon entonces` \
  `    continuar` \
  `  fin` \
  `  para cada poly en descomponerEnPoligonos(geom) hacer` \
  `    vertices <- extraerVertices(poly)` \
  `    segmentos <- build_simple_segments(vertices)` \
  `    agujeros <- []` \
  `    para cada anillo en holes(poly) hacer` \
  `      p <- polygon_centroid(anillo)` \
  `      agujeros.agregar(p)` \
  `    fin` \
  `    tri <- triangle.triangulate(vertices, segmentos, agujeros, min_angle, max_area)` \
  `    para cada t en tri hacer` \
  `      triangulosAAgregar.agregar(Polygon(t))` \
  `    fin` \
  `  fin` \
  `fin` \
  `retornar escribirComoSHP(triangulosAAgregar)`
]

]