#import "final.typ": conf, resumen, dedicatoria, agradecimientos, start-doc, end-doc, capitulo, apendice
#import "metadata.typ": example-metadata

#import "@preview/algo:0.3.4": algo, i, d

#show: conf.with(metadata: example-metadata)

#resumen(metadata: example-metadata)[
Este trabajo aborda la generación de mallas poligonales para apoyar la modelación hidrológica en cuencas urbanas y periurbanas, utilizando QGIS como plataforma de trabajo. A partir de requerimientos geométricos asociados a Unidades de Respuesta Hidrológica y de antecedentes previos que automatizaban la triangulación y disolución en QGIS, se identificó como problema principal la inestabilidad del flujo de triangulación, que podía provocar cierres inesperados del Sistema de Información Geográfica (SIG) en geometrías complejas. En este contexto, se plantea integrar el algoritmo Polylla, desarrollado originalmente en C++, y rediseñar el flujo del plugin para hacerlo operativo dentro del entorno de QGIS.

La implementación se centró en dos aportes. Primero, se desarrolló un binding para exponer Polylla desde C++ a Python mediante pybind11 y CMake, permitiendo su uso como librería en Python. Segundo, se diseñó y construyó un nuevo plugin con una arquitectura por etapas: la triangulación se ejecuta como subproceso externo y genera archivos intermedios (Shapefile), mientras que Polylla se ejecuta dentro de QGIS desde Python, convirtiendo la triangulación a formato OFF y devolviendo la malla poligonal como una capa en memoria. La interfaz se implementó con Qt Designer y se organizó en dos diálogos alineados con estas etapas, incorporando parámetros configurables para triangulación y opciones de suavizado para Polylla.

Como resultado, se obtuvo un flujo funcional que permite generar triangulaciones y mallas poligonales dentro de QGIS de forma estable en los casos demostrativos presentados, sin cierres inesperados del software. Se concluye que la separación de la triangulación como subproceso y la integración de Polylla mediante un binding a Python permiten operar el proceso completo en un entorno SIG con mayor control y menor riesgo de fallos. Queda como trabajo futuro realizar una evaluación cuantitativa más rigurosa de la calidad geométrica de las mallas mediante métricas como convexidad y factores de forma, además de explorar optimizaciones de rendimiento e integración más profunda del proceso en QGIS.

]

#dedicatoria[
    Dedicado a mi abuelo, Raúl.
]


#show: start-doc

#capitulo(title: "Introducción")[

La gestión eficiente de los recursos hídricos en zonas urbanas y periurbanas requiere herramientas de modelación capaces de representar la complejidad del territorio. Modelos hidrológicos distribuidos, como PUMMA (Peri-Urban Model for landscape MAnagment) @Jankowfsky10, basan su análisis en Unidades de Respuesta Hidrológica (URHs) @Flugel95. Estas unidades deben cumplir con requisitos geométricos, como la convexidad y ciertos parámetros de forma, para asegurar condiciones adecuadas para la simulación. En este contexto, la generación automatizada de mallas poligonales a partir de información geográfica es un desafío que combina la ingeniería en computación con la ingeniería hidráulica.

El origen de este trabajo se sitúa en la tesis de magíster de Pedro Sanzana @Sanzana12, donde se identificó que las URHs utilizadas en modelos distribuidos debían cumplir con criterios estrictos de forma, convexidad y orientación para evitar inestabilidades numéricas en las simulaciones. A partir de esos requerimientos, Sergio Villarroel @Villarroel23 desarrolló un plugin para QGIS que automatizaba la triangulación de polígonos y su posterior disolución con base en dichos criterios geométricos. Aunque ese plugin validó la factibilidad del proceso, presentaba problemas de estabilidad que provocaban cierres inesperados del software al trabajar con geometrías complejas.

Este trabajo aborda el problema de generar mallas poligonales controlando parámetros de calidad geométrica, utilizando QGIS como plataforma central. Se seleccionó esta herramienta por ser de código abierto y contar con una comunidad activa que aporta soporte y funcionalidades. El desarrollo de plugins en QGIS se realiza mediante Python, lo que otorga flexibilidad para extender el software. Sin embargo, la ejecución de código externo dentro de este ambiente presenta desafíos técnicos: la integración directa de librerías de triangulación ha generado inestabilidad, conflictos de memoria y cierres inesperados (crashes), impidiendo la automatización confiable del proceso en versiones anteriores.

Se propone abordar estas problemáticas mediante ingeniería de software e integración de algoritmos. En particular, se plantea incorporar el algoritmo Polylla @Salinas22, originalmente escrito en C++, al entorno de Python y posteriormente a QGIS. Polylla genera mallas poligonales a partir de triangulaciones arbitrarias sin introducir puntos adicionales al dominio, lo que permite mantener la fidelidad de los datos topográficos de entrada. Para ello, se propone desarrollar un binding que exporte las funcionalidades de Polylla como una librería nativa de Python. Tomando como base el trabajo de Villarroel @Villarroel23, se diseñará una nueva versión del plugin que permita generar mallas ajustando parámetros relevantes del proceso, y que rediseñe el flujo de triangulación para mejorar la estabilidad, desacoplando etapas del proceso para reducir fallos en el entorno de QGIS. El resultado esperado es una herramienta modular orientada a apoyar la preparación de datos para el modelamiento hidrológico.

== Objetivos
=== Objetivo General

Diseñar e implementar una herramienta de software integrada en QGIS que permita la generación de mallas poligonales mediante la utilización del algoritmo Polylla, asegurando estabilidad operativa y corrigiendo errores críticos presentes en versiones anteriores, con control de parámetros relevantes del proceso.

=== Objetivos Específicos

+ *Desarrollar un binding de Python para Polylla*: Crear una interfaz funcional entre el código original en C++ de Polylla y Python, permitiendo su uso como una librería estándar dentro del ecosistema de desarrollo actual.
+ *Rediseñar la arquitectura de triangulación*: Implementar un mecanismo de ejecución externa para el proceso de triangulación que evite los conflictos de memoria y crashes aleatorios observados al utilizar la librería Triangle directamente dentro del entorno de QGIS.
+ *Desarrollar un nuevo plugin para QGIS*: Integrar la nueva librería de Polylla y el flujo de triangulación corregido en un complemento de usuario final, permitiendo la manipulación de capas vectoriales y la configuración de parámetros.
+ *Demostrar el funcionamiento de la solución*: Ejecutar el flujo completo (triangulación y Polylla) en casos representativos dentro de QGIS, generando y visualizando las capas resultantes. La validación cuantitativa y la comparación con herramientas previas se dejan como trabajo futuro.

== Contenido de la memoria

El capítulo 2 (Situación Actual) revisa los antecedentes de este trabajo: la tesis de Sanzana, el plugin de Villarroel, el algoritmo Polylla y las tecnologías utilizadas, cerrando con la justificación de la propuesta frente a las limitaciones observadas. El capítulo 3 (Implementación) detalla la creación del binding, la arquitectura del plugin y las decisiones adoptadas para resolver los problemas de estabilidad en la triangulación. El capítulo 4 (Resultados) presenta casos demostrativos del flujo completo ejecutado en QGIS, mostrando la triangulación y la aplicación de Polylla sobre distintas geometrías. Finalmente, el capítulo 5 expone las conclusiones del trabajo y las líneas de desarrollo que quedan abiertas, entre ellas una evaluación cuantitativa más completa de la calidad geométrica de las mallas.

]


#capitulo(title: "Situación Actual")[

== Triangulaciones

Una triangulación de un conjunto de puntos $S$ en el plano es una subdivisión del área delimitada por la envoltura convexa de $S$ en un conjunto de triángulos que se intersectan únicamente en sus vértices y aristas compartidas. En el contexto del modelamiento numérico, estas sirven para discretizar dominios continuos en elementos finitos procesables por algoritmos computacionales.

Una de las triangulaciones estándar al día de hoy es la Triangulación de Delaunay. Esta se define como la triangulación tal que el círculo circunscrito de cada triángulo no contiene ningún otro punto del conjunto de entrada en su interior. Esta propiedad garantiza que se maximice el ángulo mínimo de todos los triángulos, evitando en la medida de lo posible la generación de triángulos "delgados".

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 12pt,
    image("imagenes/non_delaunay.svg", width: 80%),
    image("imagenes/delaunay.svg", width: 80%),
  ),
  caption: [
    Comparación entre una triangulación no-Delaunay @NoDelaunayWiki (izquierda) y la Triangulación de Delaunay @DelaunayWiki (derecha). En la versión Delaunay ningún círculo circunscrito contiene puntos del conjunto ajenos al triángulo que lo define.
  ],
) <fig-comparacion-delaunay>

Cuando el dominio incluye fronteras físicas o barreras (en el caso de mallas urbanas, caminos y cuencas), se utiliza la Triangulación de Delaunay con Restricciones (_Constrained Delaunay triangulation_, CDT). A diferencia de la versión estándar, la CDT permite definir segmentos que deben aparecer obligatoriamente como aristas en la malla final, incluso si esto implica no satisfacer localmente la condición de Delaunay.

#figure(
        image("imagenes/guitar_original.png", width: 60%),
        caption: [Guitarra eléctrica PSLG. @Shewchuk96],
)

#figure(
        image("imagenes/guitar_delaunay.png", width: 60%),
        caption: [Triangulación de Delaunay sobre el PSLG. @Shewchuk96],
)

#figure(
        image("imagenes/guitar_CDT.png", width: 60%),
        caption: [Triangulación de CDT sobre el PSLG. @Shewchuk96],
)

=== La librería Triangle
La librería Triangle @Shewchuk96 es la implementación de referencia en la investigación académica para la generación de mallas de Delaunay en dos dimensiones. Su núcleo es el algoritmo de Refinamiento de Delaunay de Ruppert @Ruppert95, el cual permite construir mallas de "calidad garantizada", entendida como la ausencia de triángulos con ángulos menores a un umbral definido por el usuario.

#figure(
        image("imagenes/guitar_CDT_0Holes.png", width: 60%),
        caption: [Triangulación de CDT sobre el PSLG con triángulos removidos de cavidades y agujeros. @Shewchuk96],
)

#figure(
        image("imagenes/guitar_CDT_20min.png", width: 60%),
        caption: [Triangulación de con el Refinamiento de Ruppert con 20° de ángulo mínimo. @Shewchuk96],
)

El proceso parte de una CDT del dominio de entrada y procede de forma iterativa insertando vértices adicionales —denominados puntos de Steiner— hasta que la malla satisface las restricciones de calidad solicitadas @Shewchuk96. La inserción de estos puntos se rige por dos reglas de prioridad:

+ *Invasión de segmentos (_encroachment_):* Se dice que un segmento es "invadido" si algún vértice de la malla cae dentro de su círculo diametral. Cuando esto ocurre, el segmento se divide insertando un vértice en su punto medio, reduciendo así el radio del círculo de los subsegmentos resultantes. Los segmentos invadidos tienen prioridad sobre cualquier otro tipo de refinamiento.

#figure(
        image("imagenes/encroachment.png", width: 70%),
        caption: [Se dividen segmentos recursivamente hasta que no haya invasión de segmento. @Shewchuk96],
)

+ *Triángulos malos (_bad triangles_):* Un triángulo se considera malo si su ángulo mínimo es inferior al umbral solicitado o si su área supera el máximo definido. En tal caso, se inserta un nuevo vértice en el circuncentro del triángulo, lo que garantiza su eliminación por la propiedad de Delaunay. Si este nuevo vértice resultara a su vez en la invasión de algún segmento, la inserción se revierte y los segmentos afectados se dividen.

#figure(
        image("imagenes/bad_triangle.png", width: 70%),
        caption: [Cada triángulo malo se divide poniendo un vértice en su circuncentro. @Shewchuk96],
)

Ruppert @Ruppert95 demostró que este procedimiento converge para restricciones de ángulo mínimo de hasta 20.7°, y en la práctica Triangle opera de manera confiable con ángulos de hasta 33° @Shewchuk96. El usuario controla la calidad de la malla mediante dos parámetros principales: el ángulo mínimo permitido y el área máxima de los triángulos.

== Simulación Hidrológica

La modelación hidrológica distribuida de cuencas peri-urbanas requiere definir con precisión la unidad espacial que representa el territorio. La discretización del espacio en unidades homogéneas determina tanto la calidad de la representación física como la estabilidad numérica del modelo. A diferencia de los modelos basados en grillas regulares, los modelos vectoriales permiten representar elementos de tamaño variable y preservar barreras hidrológicas naturales y artificiales (calles, canales y colectores) que modifican significativamente la dirección del flujo superficial @Sanzana12.

En este contexto, el modelo hidrológico distribuido PUMMA (_Peri-Urban Model for landscape MAnagement_) @Jankowfsky10 basa su representación espacial en un enfoque vectorial que combina dos tipos de unidades: los Elementos Hidrológicos Urbanos (EHU) para zonas urbanas y las Unidades de Respuesta Hidrológica (URH) para zonas peri-urbanas y naturales.

=== Unidades de Respuesta Hidrológica

El concepto de Unidades de Respuesta Hidrológica fue propuesto por Flügel @Flugel95. Una URH es una unidad espacial que representa un sector del territorio con propiedades físicas homogéneas de evaporación, infiltración, rugosidad y dirección de flujo. El supuesto fundamental es que la dinámica de los procesos hidrológicos al interior de cada URH debe ser menor que la dinámica de los procesos entre diferentes URHs @Sanzana12.

=== Requerimientos geométricos de la malla

Para que el modelo PUMMA pueda calcular correctamente los flujos entre unidades adyacentes, la malla de URHs debe satisfacer requisitos topológicos y numéricos. Específicamente, el cálculo del flujo lateral entre dos unidades se realiza mediante la Ley de Darcy, en la que el caudal de descarga depende, entre otros factores, de la distancia entre los centros de gravedad de los polígonos adyacentes @Sanzana12. Esto implica que si el centroide de un polígono se encuentra fuera de su propio contorno, situación que ocurre en polígonos muy cóncavos o alargados, la distancia calculada no tiene representación física real y los cálculos de flujo resultan incorrectos.

En consecuencia, para una correcta aplicación del modelo es necesario corregir aquellos elementos mal formados de la malla de entrada, que corresponden a polígonos con centroides fuera del polígono, bordes mal representados, área excesiva, o alta variabilidad interna de alguna propiedad física como la pendiente @Sanzana12.

=== Descriptores de forma

Para identificar de manera sistemática los polígonos que no satisfacen los criterios geométricos del modelo, Sanzana @Sanzana12 propuso el uso de descriptores de forma. Estos son índices numéricos que caracterizan la geometría de un polígono en función de la distribución de su área y su perímetro. En la Tabla siguiente se muestran los cuatro descriptores considerados:
#align(center, [
  #table(
  columns: (auto, auto),
  align: (left, center),
  table.header([*Descriptor*], [*Expresión*]),
  [Factor de Forma],
  [$F F = (4 pi A) / P^2$],
  [Compacidad],
  [$C = sqrt(4 pi A) / P$],
  [Índice de Solidez],
  [$S I = A / A_"conv"$],
  [Índice de Convexidad],
  [$C I = P_"conv" / P$],
)
])

Donde $A$ y $P$ son el área y el perímetro del polígono, y $A_"conv"$ y $P_"conv"$ corresponden al área y al perímetro de su cerradura convexa. Todos los índices toman valores en $(0, 1]$, siendo $1$ el valor correspondiente a un polígono perfectamente convexo (o circular, para $FF$ y $C$).

El Factor de Forma y la Compacidad permiten identificar polígonos delgados y alargados, siendo el Factor de Forma más sensible a elementos de área pequeña. Los Índices de Solidez y Convexidad cuantifican el grado de convexidad comparando el polígono con su cerradura convexa. El Índice de Convexidad, al basarse en perimetros, resulta más sensible que el Índice de Solidez en polígonos con contornos muy irregulares que aumentan el perímetro sin aumentar el área @Sanzana12.

Mediante un análisis de sensibilidad aplicado sobre las cuencas Mercier y Chaudanne de Lyon, Francia, Sanzana @Sanzana12 determinó que el Índice de Convexidad es el descriptor más adecuado para identificar polígonos mal formados, estableciendo un valor límite de $C I = 0.75$ por encima del cual un polígono se considera bien formado para el modelo hidrológico.

== Generación de Mallas

Dado que la triangulación directa de una URH produce un número excesivo de polígonos triangulares que incrementan el costo computacional del modelo hidrológico y reducen la representatividad de la malla @Villarroel23, se han propuesto estrategias que parten de una triangulación de calidad y la transforman en una malla de polígonos más compacta. A continuación se describen las dos estrategias relevantes para este trabajo.

=== Estrategia de Disolución

En su memoria, Villarroel @Villarroel23 propuso un método de dos etapas para mejorar las URHs de mala calidad geométrica. En la primera etapa se genera una CDT de calidad sobre el polígono de entrada, utilizando la librería Triangle con parámetros configurables de ángulo mínimo y área máxima. Esto asegura que los triángulos resultantes tengan una distribución uniforme y eviten ángulos degenerados.

El algoritmo generador de la triangulación es el siguiente:

#figure(
  algo(
    title: "Triangle Features",
    parameters: ([Features],),
    strong-keywords: true,
    stroke: 0.5pt,
    inset: 8pt,
    column-gutter: 10pt,
    row-gutter: 5pt,
  )[
    $italic("featuresToAdd") <- [space]$ \
    *for* $italic("Feature")$ *in* $italic("Features")$ *do* #i \
      $italic("geometry") <- italic("Feature.getGeometry()")$ \
      *if* $italic("geometry")$ *is well shaped* *then* #i \
        *continue* #d \
      $italic("polyVertices") <- $ Points from $italic("geometry")$ \
      $italic("polySegments") <- $ Build segments from $italic("geometry")$ \
      $italic("polyHoles") <- $ Build holes from $italic("geometry")$ \
      $italic("triangledFeature") <- $ Call Triangle$(italic("polyVertices"),
        italic("polySegments"), italic("polyHoles"))$ \
      Add $italic("triangledFeature")$ to $italic("featuresToAdd")$ #d \
    *Return and Draw* $italic("featuresToAdd")$
  ],
  caption: [
    Algoritmo de triangulación de _features_ utilizando la librería Triangle @Villarroel23.
  ],
) <alg-triangle-features>

En la segunda etapa se aplica un proceso de disolución iterativa sobre la triangulación obtenida. El algoritmo recorre los triángulos de la malla y fusiona cada uno con el vecino adyacente de mayor área, siempre que el polígono resultante de la fusión satisfaga el descriptor de forma umbral definido por el usuario. Este proceso se repite hasta que ninguna fusión adicional sea posible sin violar las restricciones geométricas @Villarroel23.

El algoritmo que determina a los vecinos es el siguiente:

#figure(
  algo(
    title: "Build Neighbours",
    parameters: ([dictFeatures],),
    strong-keywords: true,
    stroke: 0.5pt,
    inset: 8pt,
    column-gutter: 10pt,
    row-gutter: 5pt,
  )[
    $italic("dictNeighbours") <- [space]$ \
    *for* $italic("feature")$ *in* $italic("dictFeatures")$ *do* #i \
      $italic("boundingBox") <- italic("feature.getBoundingBox()")$ \
      $italic("candidateNeighbours") <- [space]$ \
      *for* $italic("candidate")$ *in* $italic("dictFeatures")$ *do* #i \
        *if* $italic("candidate")$ *intersects* $italic("boundingBox")$ *then* #i \
          Add $italic("candidate")$ to $italic("candidateNeighbours")$ #d \
      #d \
      *for* $italic("candidate")$ *in* $italic("candidateNeighbours")$ *do* #i \
        *if* $italic("feature")$ shares 2 vertices with
          $italic("possibleNeighbour")$ *then* #i \
          Add $italic("candidate")$ as neighbour of $italic("feature")$
          in $italic("dictNeighbours")$ #d \
      #d \
    #d \
  ],
  caption: [
    Algoritmo de construcción del grafo de vecindad entre triángulos @Villarroel23.
  ],
) <alg-build-neighbours>

Los descriptores de forma implementados para controlar la disolución son los siguientes:

- *Factor de Forma*
- *Compacidad*
- *Índice de Solidez*
- *Índice de Convexidad*

Finalmente, el algoritmo que disuelve los polígonos es el siguiente:
#figure(
  algo(
    title: "Dissolve Features",
    parameters: ([dictFeatures, dictNeighbours, shapeThreshold, maxArea],),
    strong-keywords: true,
    stroke: 0.5pt,
    inset: 8pt,
    column-gutter: 10pt,
    row-gutter: 5pt,
  )[
    sort $<- italic("dictFeatures")$ \
    *while* $italic("dictFeatures")$ *is not empty do* #i \
        $italic("feature") <- italic("dictFeatures.pop")$ \
        $italic("sortedNeighbours") <-$ sort $italic("sortNeighbours.get(feature)")$ \
        *for* $italic("neighnour")$ *in* $italic("sortedNeighbours")$ *do* #i \
            $italic("union") <-$ Union$(italic("feature"), italic("neighbour"))$ \
            *if* $italic("union")$ follow restriction *then* #i \
                add $italic("union")$ to $italic("dictFeatures")$\
                remove $italic("neighnour")$ from $italic("dictFeatures")$\
                refresh neighbours\
                sort $italic("dictFeatures")$\
                break #d #d\
        *if* $italic("no available neighbours")$ *then* #i \
            add $italic("feature")$ to $italic("dissolvedFeatures")$\
            remove all neighbours references to $italic("feature")$ #d #d\
    *Return and draw* $italic("dissolvedFeatures")$
  ],
  caption: [
    Algoritmo de disolución iterativa de triángulos @Villarroel23.
  ],
) <alg-dissolve-features>

#figure(
        image("imagenes/villarroel_URH.png", width: 80%),
        caption: [Triangulación de una URH: (a) sin triangulación (b) triangulación de Delaunay (c) triangulación CDT sin criterios de calidad (d) triangulación con 20° de ángulo mínimo. @Villarroel23],
)

Si bien esta estrategia permite obtener polígonos que satisfacen criterios geométricos configurables, el plugin de QGIS desarrollado en dicho trabajo presentó problemas de inestabilidad al ejecutar la librería Triangle directamente dentro del proceso de QGIS, provocando cierres inesperados del software en geometrías complejas @Villarroel23.

== Algoritmo Polylla

Por otro lado, Salinas et al. @Salinas22 propusieron el algoritmo Polylla, un método indirecto de generación de mallas poligonales que parte de una triangulación de entrada y produce una malla de polígonos sin insertar ni eliminar ningún vértice. El algoritmo se basa en el concepto de _regiones de arista terminal_ (_terminal-edge regions_) @Salinas22 y se divide en tres fases: etiquetado, recorrido y reparación.

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 12pt,
    image("imagenes/pikachutriangulization.png", width: 80%),
    image("imagenes/pikachuPolylla.png", width: 80%),
  ),
  caption: [
    Comparación de un Pikachu triangulizado (izquierda) con uno al que se le aplico el algoritmo Polylla (derecha). @Salinas22
  ],
) <fig-comparacion-polylla>

=== Conceptos fundamentales

El punto de partida es clasificar cada arista de la triangulación según su longitud relativa en los dos triángulos que la comparten @Salinas22. Esta clasificación produce tres tipos de aristas:

- *Arista terminal (_terminal-edge_):* es la arista más larga de los dos triángulos que la comparten simultáneamente. Estas aristas son la base estructural del algoritmo.

- *Arista frontera (_frontier-edge_):* no es la arista más larga de ninguno de los dos triángulos que la comparten. Las aristas frontera delimitan los polígonos finales.

- *Arista interna (_internal-edge_):* es la arista más larga de exactamente uno de los dos triángulos que la comparten.

A partir de este etiquetado se define la *región de arista terminal*: el conjunto de todos los triángulos $t_i$ de la triangulación cuyo camino de propagación de arista más larga (_Longest-Edge Propagation Path_ o LEPP) comparte la misma arista terminal. Una propiedad clave es que estas regiones cubren todo el dominio sin solapamiento, lo que garantiza que la partición resultante sea una malla válida @Salinas22.

=== Las tres fases del algoritmo

*Fase 1 — Etiquetado (_Label Phase_):* Se itera sobre todos los triángulos de la triangulación para identificar la arista más larga de cada uno. En una segunda iteración sobre las aristas, se clasifica cada una como terminal, frontera o interna según la definición anterior. Se selecciona además un "triángulo semilla" por cada región de arista terminal @Salinas22.

*Fase 2 — Recorrido (_Traversal Phase_):* Partiendo del "triángulo semilla" de cada región, el algoritmo recorre los triángulos vecinos por sus aristas internas y registra los vértices de las aristas frontera en sentido antihorario para construir el polígono @Salinas22. El resultado puede ser un polígono simple o un polígono no simple si la región contiene aristas internas que actúan como barreras (_barrier-edges_).

*Fase 3 — Reparación (_Reparation Phase_):* Los polígonos no simples son subdivididos en polígonos simples promoviendo algunas aristas internas incidentes en los puntos extremos de las _barrier-edges_ a la categoría de aristas frontera @Salinas22.

=== Complejidad computacional

Una ventaja central de Polylla frente a la estrategia de disolución es su complejidad computacional. Salinas et al. @Salinas22 demostraron que las tres fases del algoritmo tienen costo $O(m)$ cada una, siendo $m$ el número de triángulos de la triangulación de entrada, con $m = O(n)$ donde $n$ es el número de puntos. Por lo tanto, la complejidad total del algoritmo es $O(n)$ tanto en tiempo como en memoria @Salinas22.

Esto contrasta con la estrategia de disolución de Villarroel @Villarroel23, cuyo proceso iterativo de fusión de triángulos depende de la estructura de vecindad generada por la triangulación inicial. En el peor caso, la disolución puede requerir revisar repetidamente el conjunto de polígonos hasta que no sea posible ninguna fusión adicional que respete los criterios geométricos, lo que puede escalar hasta $O(n^3)$ en función del número de elementos.

=== Relevancia para el problema

Polylla presenta varias características que lo hacen especialmente adecuado como alternativa a la estrategia de disolución para la generación de mallas de URHs:

En primer lugar, su complejidad lineal $O(n)$ garantiza tiempos de ejecución predecibles y acotados, lo que es crítico para la automatización del proceso dentro del entorno de QGIS, donde la inestabilidad del tiempo de ejecución es uno de los problemas identificados @Villarroel23.

En segundo lugar, Polylla respeta exactamente el conjunto de puntos de la triangulación de entrada sin añadir vértices adicionales @Salinas22. Esto preserva la fidelidad geométrica de los bordes de las URHs, que corresponden a contornos físicos significativos como límites de uso de suelo, subcuencas o red de drenaje @Sanzana12.

En tercer lugar, el algoritmo es determinístico: dado el mismo conjunto de puntos y la misma triangulación, produce siempre el mismo resultado @Salinas22. Esto contrasta con la estrategia de disolución, cuyo resultado depende del orden en que se procesan los triángulos vecinos @Villarroel23, introduciendo variabilidad en la malla final.

Finalmente, Polylla es capaz de procesar geometrías complejas con agujeros (_holes_) @Salinas22, lo que resulta relevante para cuencas hidrológicas que incluyen islas o polígonos interiores, uno de los casos problemáticos identificados originalmente por Sanzana @Sanzana12.

== Sistemas de Información Geográfica (SIG)

Un Sistema de Información Geográfica (SIG) es un sistema computacional diseñado para capturar, almacenar, manipular, analizar y desplegar información georeferenciada, con el fin de resolver problemas complejos de planificación y gestión territorial. En el contexto de la modelación hidrológica, el uso de un SIG resulta óptimo dado el volumen de información que debe ser gestionada, y porque permite representar los elementos del territorio tanto en formato ráster como vectorial @Villarroel23.

En la representación *vectorial*, los objetos geográficos se codifican como puntos, líneas o polígonos. En la representación *ráster*, el territorio se divide en una grilla de píxeles, cada uno con el valor de la propiedad que se desea modelar. Para la representación de URHs se emplea exclusivamente el modelo vectorial, ya que las unidades de respuesta hidrológica son por definición polígonos irregulares @Villarroel23.

=== QGIS y el ecosistema PyQGIS
QGIS es una plataforma de código abierto para sistemas de información geográfica, ampliamente utilizada en investigación académica y en aplicaciones industriales. Su arquitectura permite extender las funcionalidades del software mediante _plugins_ escritos en Python, a través de la API PyQGIS.

Sin embargo, la ejecución de código externo intensivo dentro del proceso de QGIS presenta restricciones en la gestión de memoria y en el manejo de subprocesos. En particular, el uso de librerías compiladas en C, como Triangle, dentro del mismo espacio de memoria del proceso principal de QGIS puede provocar errores de segmentación y cierres del software, especialmente al procesar geometrías complejas o mallas de gran tamaño @Villarroel23. Este problema motiva el rediseño de la arquitectura del plugin abordado en el presente trabajo.

]

#capitulo(title: "Implementación de la solución")[
== Requerimientos de la solución

El plugin debe permitir ejecutar un flujo de dos etapas: primero la triangulación de una capa poligonal de entrada, con parámetros de calidad configurables (ángulo mínimo y área máxima), y luego la generación de una malla poligonal mediante Polylla sobre la triangulación resultante. Ambas etapas pueden ejecutarse de forma independiente o secuencial.

Dos restricciones condicionaron las decisiones de implementación. La primera es la estabilidad: la ejecución de la triangulación no debe cerrar QGIS de forma abrupta ante geometrías complejas o fallos de la librería. La segunda es el aislamiento de fallos: si una etapa falla, el error debe quedar contenido y reportarse al usuario sin afectar el proceso principal del SIG. Estas dos restricciones son las que motivaron la arquitectura descrita en la sección siguiente.

== Arquitectura general de la solución

La solución se organiza en dos etapas con mecanismos de ejecución distintos. La triangulación se ejecuta como subproceso externo al proceso principal de QGIS, de modo que cualquier fallo quede contenido y no produzca un cierre inesperado del SIG. Polylla, en cambio, se ejecuta dentro del entorno Python de QGIS mediante el binding desarrollado, como una tarea asíncrona que no bloquea la interfaz.

=== Componentes

La solución se compone de los siguientes elementos:
+ Interfaces de usuario en QGIS: la interfaz de triangulación permite seleccionar la capa de entrada, configurar parámetros y definir rutas de salida para los productos de la triangulación, mientras que la interfaz de Polylla permite seleccionar una capa de entrada y el nombre de la capa de salida.

+ Núcleo del plugin (Python, PyQGIS): implementa la lógica de control del flujo. Sus responsabilidades incluyen validar entradas, preparar directorios, construir comandos de ejecución, manejar archivos intermedios y transformar resultados en capas QGIS.


+ Librería Polylla para Python (binding): trae el código C++ de Polylla al entorno Python. El plugin invoca esta librería para construir la malla poligonal a partir de la triangulación.

=== Flujo de ejecución

El flujo comienza con la selección de una capa vectorial poligonal en QGIS y la configuración de parámetros de triangulación. El plugin valida la entrada y lanza el script `triangulation.py` como subproceso, pasándole los parámetros configurados. El resultado se escribe en disco como un Shapefile de triángulos, lo que deja un producto intermedio persistente que puede inspeccionarse o reutilizarse sin repetir la ejecución completa.

Una vez disponible la capa triangulada, el usuario puede ejecutar Polylla desde el segundo diálogo. El plugin convierte la capa al formato `OFF`, ejecuta Polylla mediante `py_polylla` dentro de una `QgsTask` y carga el resultado como una nueva capa en memoria en el proyecto de QGIS.

#figure(
        image("imagenes/diagrama.png", width: 90%),
        caption: [Diagrama del flujo de ejecución del plugin en QGIS.],
)


== Integración de Polylla

El algoritmo Polylla fue desarrollado originalmente en C++ y su uso dentro de QGIS requiere una interfaz hacia Python, dado que los plugins de QGIS se implementan en PyQGIS. En esta sección se describe el código base reutilizado, el diseño del binding implementado con pybind11, el proceso de construcción del módulo mediante CMake y la API final disponible desde Python.

=== Descripción del código base

La implementación original de Polylla se reutiliza como base sin modificar su lógica principal. El núcleo del algoritmo se encuentra definido en polylla.hpp, donde se declara la estructura PolyllaOptions para configurar aspectos del algoritmo y la clase Polylla, responsable de ejecutar el proceso de generación de mallas poligonales a partir de una triangulación.

Polylla opera sobre una representación de malla triangulada basada en estructuras topológicas, apoyándose en triangulation.hpp y componentes relacionados. Este enfoque permite recorrer adyacencias y relaciones entre elementos, lo cual es necesario para construir regiones y fusionar triángulos. En el código base también se incorpora la medida m_edge_ratio mediante m_edge_ratio.hpp, utilizada por Polylla para evaluar calidad o suavizado de las mallas resultantes.

Desde el punto de vista de entradas, el proyecto original contempla la construcción de Polylla a partir de archivos externos, incluyendo formatos como `OFF` y el conjunto de archivos .node, .ele y .neigh, que son extensiones comunes de triangulaciones generadas por triangle. Desde el punto de vista de salidas, la implementación original permite exportar resultados en distintos formatos mediante métodos que escriben archivos, pero para los fines del plugin se utilizó la exportación en formato `OFF` para representar la malla poligonal resultante.

=== Binding: Creación de py_polylla

Para habilitar el uso de Polylla desde Python se implementó un módulo con `pybind11`, que se llamó `py_polylla`. Este módulo expone una interfaz acotada, centrada en la configuración del algoritmo y en su ejecución a partir de archivos de triangulación.

El binding expone dos elementos principales:

+ *PolyllaOptions:* se expone como clase Python con sus campos configurables mediante `def_readwrite`. Los atributos expuestos corresponden a `smooth_method`, `smooth_iterations` y `target_length`, consistentes con la estructura declarada en `polylla.hpp`.

+ *Polylla:* se expone como clase Python con constructores que reciben rutas a archivos y una instancia opcional de `PolyllaOptions`. En el plugin se utiliza el constructor que recibe archivos en formato `OFF`.

Para construir el módulo se utilizó `CMake` junto con `pybind11`. El archivo `CMakeLists.txt` localiza el entorno de Python para obtener sus headers y librerías, incorpora `pybind11` como dependencia y compila el wrapper como una biblioteca compartida importable desde Python.

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

=== Construcción de la representación OFF

A partir de la capa triangulada, el plugin construye la representación de entrada para Polylla en formato `OFF` mediante la función `build_off_from_layer`. Esta función recorre los triángulos de la capa y genera dos estructuras: un arreglo de vértices y un arreglo de caras, donde cada cara es una terna de índices hacia el arreglo de vértices. Dado que vértices adyacentes entre triángulos aparecen duplicados en la representación de la capa, se aplica una deduplicación basada en redondeo de coordenadas: los valores (x, y) se cuantizan a una cantidad fija de decimales antes de registrar cada vértice en el índice global, de modo que puntos coincidentes queden mapeados a una misma entrada.


=== Ejecución de Polylla

El puente principal de ejecución se implementa en `run_polylla_off`. Este método recibe el archivo OFF temporal generado desde la capa triangulada, construye una instancia de `PolyllaOptions` con los parámetros configurados en el diálogo y ejecuta Polylla, produciendo un nuevo archivo OFF que representa la malla poligonal resultante.

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

- Selección de directorio de salida mediante un selector de archivos.

- Parámetros: ángulo mínimo y área máxima.

- Descriptor de forma (_shape descriptor_) y umbral (_threshold_): permiten filtrar triángulos según una medida de calidad geométrica antes de pasarlos a Polylla. El umbral se habilita condicionalmente según el descriptor seleccionado.

- Botones de ejecución y cancelación.

La triangulación se ejecuta invocando el script triangulation.py como subproceso, pasando los parámetros seleccionados y construyendo la ruta de salida en base al nombre de la capa.

#figure(
        image("imagenes/triangulation.png", width: 60%),
        caption: "Ventana de diálogo para la triangulación de una capa poligonal.",
    )

=== Diálogo de Polylla

El dialogo de Polylla permite seleccionar la capa triangulada (capas poligonales) y configurar parámetros de suavizado:

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


#capitulo(title: "Resultados")[


En este capítulo se presenta evidencia visual del funcionamiento del plugin en QGIS. El objetivo es mostrar el flujo completo de trabajo, desde una capa poligonal de entrada, pasando por la triangulación, hasta la generación de una malla poligonal mediante Polylla. Los casos se eligieron para cubrir situaciones típicas del uso esperado, variando la complejidad geométrica y la presencia de agujeros. En cada caso se muestran tres etapas: (i) geometría de entrada sin triangular, (ii) triangulación generada y (iii) malla poligonal resultante tras aplicar Polylla.

--*FALTARÍA AGREGAR EL NÚMERO DE TRIANGULOS DE INPUT Y POLIGONOS DE SALIDA*--

#pagebreak()
== Caso 1: Figura simple sin agujeros

Este caso corresponde a una geometría simple y regular, utilizada como verificación básica del flujo completo.


#figure(
        image("imagenes/qgis1.png", width: 55%),
        caption: "Caso 1 (a): capa poligonal de entrada, sin triangular.",
    )
#figure(
        image("imagenes/qgis1tri.png", width: 55%),
        caption: "Caso 1 (b): capa triangulada (min_angle=20, max_area=1000).",
    )
#figure(
        image("imagenes/qgis1pol.png", width: 55%),
        caption: "Caso 1 (c): capa poligonal resultante tras aplicar Polylla.",
    )

== Caso 2: Figura compleja sin agujeros

Este caso utiliza una geometría sin agujeros, pero con mayor complejidad que el caso anterior debido a los múltiples irregularidades del contorno que lo deforman, para observar el comportamiento del flujo en contornos más irregulares.


#figure(
        image("imagenes/qgis2.png", width: 55%),
        caption: "Caso 2 (a): capa poligonal de entrada, sin triangular.",
    )

#figure(
        image("imagenes/qgis2tria.png", width: 55%),
        caption: "Caso 2 (b): capa triangulada (min_angle=20, max_area=1000).",
    )

#figure(
        image("imagenes/qgis2pol.png", width: 55%),
        caption: "Caso 2 (c): capa poligonal resultante tras aplicar Polylla.",
    )

== Caso 3: Figura simple con agujeros

Este caso incluye agujeros en la geometría, lo que requiere que la triangulación incorpore correctamente los vacíos internos para que el resultado final los preserve al aplicar Polylla.

#figure(
        image("imagenes/qgis3.png", width: 55%),
        caption: "Caso 3 (a): capa poligonal de entrada, con agujeros, sin triangular.",
    )

#figure(
        image("imagenes/qgis3tri.png", width: 55%),
        caption: "Caso 3 (b): capa triangulada (min_angle=20, max_area=1000).",
    )

#figure(
        image("imagenes/qgis3pol.png", width: 55%),
        caption: "Caso 3 (c): capa poligonal resultante tras aplicar Polylla.",
    )

== Caso 4: Figura compleja con agujeros

Este caso corresponde a una geometría más compleja, con agujeros, caminos y contornos irregulares, representativa de entradas difíciles dentro del flujo del plugin.


#figure(
        image("imagenes/qgis4.png", width: 55%),
        caption: "Caso 4 (a): capa poligonal de entrada, con agujeros, sin triangular.",
    )

#figure(
        image("imagenes/qgis4tri.png", width: 55%),
        caption: "Caso 4 (b): capa triangulada (min_angle=20, max_area=1000).",
    )

#figure(
        image("imagenes/qgis4pol.png", width: 55%),
        caption: "Caso 4 (c): capa poligonal resultante tras aplicar Polylla.",
    )

== Observaciones generales.

En los cuatro casos se observa que el flujo completo se ejecuta exitosamente, generando salidas en cada etapa (triangulación y posterior aplicación de Polylla). La triangulación se ejecuta con los parámetros definidos (ángulo mínimo y área máxima), y Polylla genera una malla poligonal a partir de la triangulación sin introducir puntos adicionales al dominio. En los casos con agujeros, el resultado final preserva los vacíos internos definidos en la geometría de entrada. En ninguno de los casos presentados se observaron cierres inesperados de QGIS, mostrando un funcionamiento estable del enfoque adoptado para este conjunto de pruebas.


]

#capitulo(title: "Experimentación y Evaluación")[

En construcción.

#figure(
        image("imagenes/scatter_time_vs_triangles.png", width: 75%),
        caption: "Comparación de tiempo de ejecución de Polylla vs Algoritmo de Disolución de Villarroel para " + $A_max = 200000 $ +", "+ $F F=0.8 $ +", " + $C I = 0.95$ + ".",
    )

]

#capitulo(title: "Conclusiones y trabajo futuro")[

En construcción.

== Conclusiones

En este trabajo se integró el algoritmo Polylla, originalmente en C++, en QGIS mediante la creación de una librería de Python a través de un binding, lo que permitió ejecutar Polylla desde el entorno de un plugin. En paralelo, se rediseñó el flujo de generación de mallas a partir del trabajo previo, separando la etapa de triangulación de la etapa de aplicación de Polylla. Esta decisión permitió aislar la triangulación como un subproceso externo y reducir los cierres inesperados de QGIS que ocurrían en la solución anterior durante la generación de triangulaciones en geometrías complejas.

Como resultado, se implementó un plugin con un flujo de trabajo completo: selección de una capa poligonal, triangulación con parámetros configurables (ángulo mínimo y área máxima) y posterior generación de una malla poligonal mediante Polylla. La interfaz se organizó en dos diálogos alineados con estas etapas, permitiendo ejecutar el proceso y obtener salidas en disco para la triangulación y en memoria para la malla poligonal final. En los casos demostrativos presentados se observó un funcionamiento estable del flujo, sin cierres inesperados de QGIS.

--PARRAFO SOBRE EXPERIMENTACIÓN--

Durante el desarrollo se intentaron alternativas que no pudieron adoptarse. La triangulación con SciPy se descartó debido a limitaciones para controlar parámetros necesarios del proceso. Asimismo, la ejecución mediante QProcess no funcionó de forma consistente en el contexto del plugin, por lo que se optó por una invocación de subproceso desde Python. En la integración de Polylla también se decidió no incorporar la funcionalidad de GPU del proyecto original, con el fin de simplificar la implementación y concentrarse en una versión CPU compatible con el flujo del plugin.

== Trabajo futuro

Quedan abiertas varias líneas de trabajo para extender y evaluar la solución. En primer lugar, por limitaciones de tiempo, no se realizó un conjunto de pruebas cuantitativas para caracterizar el efecto de Polylla sobre la calidad geométrica de las mallas en distintos tipos de cuencas en comparación con la disolución presentanda por Villarroel @Villarroel23 en su memoria. Se recomendaría definir un diseño experimental sistemático y medir métricas como convexidad e índices de forma (por ejemplo, factor de forma), comparando resultados para distintas combinaciones de parámetros de triangulación y opciones de Polylla.

En segundo lugar, también es posible explorar la incorporación de la versión con GPU del proyecto original de Polylla, así como añadir herramientas dentro del plugin para cálculo y visualización de métricas de calidad directamente en QGIS, facilitando el análisis y la comparación de mallas en un mismo entorno.


]


#show: end-doc

