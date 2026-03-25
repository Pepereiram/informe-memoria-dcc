== Triangulaciones

Una triangulación de un conjunto de puntos $S$ en el plano es una subdivisión del área delimitada por la envoltura convexa de $S$ en un conjunto de triángulos que se intersectan únicamente en sus vértices y aristas compartidas. En el contexto del modelamiento numérico, estas sirven para discretizar dominios continuos en elementos finitos procesables por algoritmos computacionales.

Una de las triangulaciones estándar al día de hoy es la Triangulación de Delaunay. Esta se define como la triangulación tal que el círculo circunscrito de cada triángulo no contiene ningún otro punto del conjunto de entrada en su interior. Esta propiedad garantiza que se maximice el ángulo mínimo de todos los triángulos, evitando en la medida de lo posible la generación de triángulos "delgados".

// [ NOTA FIGURA — no requiere permiso especial ]
// Aquí va la figura comparativa de círculos circunscritos.
// Fuente recomendada: Wikipedia (dominio público / CC-BY-SA).
// Etiqueta sugerida: #figure(..., caption: [Comparación entre una
// triangulación no-Delaunay (izquierda) y la Triangulación de Delaunay
// (derecha). En la versión Delaunay ningún círculo circunscrito
// contiene puntos del conjunto ajenos al triángulo que lo define.
// Adaptado de @WikiDelaunay.])
// Agrega la entrada bibliográfica correspondiente a Wikipedia si la usas.

Cuando el dominio incluye fronteras físicas o barreras (en el caso de mallas urbanas, caminos y cuencas), se utiliza la Triangulación de Delaunay con Restricciones (_Constrained Delaunay triangulation_, CDT). A diferencia de la versión estándar, la CDT permite definir segmentos que deben aparecer obligatoriamente como aristas en la malla final, incluso si esto implica no satisfacer localmente la condición de Delaunay.

// [ NOTA FIGURA — requiere citar fuente ]
// Aquí va la Figura 9 del paper de Shewchuk @Shewchuk96, que muestra
// la CDT y la malla refinada resultante (guitarra con ángulo mín. 20°).
// Como es una figura de un paper publicado, cítala explícitamente:
// caption: [Triangulación de Delaunay con Restricciones y posterior
// refinamiento con ángulo mínimo de 20°. Fuente: @Shewchuk96.]
// Verifica con tu universidad si basta la cita o si necesitas permiso
// del autor para reproducirla en un trabajo publicado en biblioteca.

AGREGAR:
+ IMAGENES DE CIRCULOS CIRCUNSCRITO no-delaunay vs Delaunay wiki
+ triangulo obstuso mostrando el punto nuevo dentro del ciruclo (fig 11 del papaer triangle)
+ figura 9 de triangle.pdf para mostrar como CDT y el refinamiento de rupert funcionan
+ mostrar algun ejemplo de malla hidrologica si es posible

=== La librería Triangle
La librería Triangle @Shewchuk96 es la implementación de referencia en la investigación académica para la generación de mallas de Delaunay en dos dimensiones. Su núcleo es el algoritmo de Refinamiento de Delaunay de Ruppert @Ruppert95, el cual permite construir mallas de "calidad garantizada", entendida como la ausencia de triángulos con ángulos menores a un umbral definido por el usuario.

// [ NOTA CITA ]
// @Ruppert95 corresponde a: Ruppert, J. (1995). A Delaunay refinement
// algorithm for quality 2-dimensional mesh generation. Journal of
// Algorithms, 18(3), 548–585. Agrégala a tu archivo .bib si no la
// tienes aún; es la fuente primaria del algoritmo, distinta de @Shewchuk96.

El proceso parte de una CDT del dominio de entrada y procede de forma iterativa insertando vértices adicionales —denominados puntos de Steiner— hasta que la malla satisface las restricciones de calidad solicitadas @Shewchuk96. La inserción de estos puntos se rige por dos reglas de prioridad:

+ *Invasión de segmentos (_encroachment_):* Se dice que un segmento es "invadido" si algún vértice de la malla cae dentro de su círculo diametral. Cuando esto ocurre, el segmento se divide insertando un vértice en su punto medio, reduciendo así el radio del círculo de los subsegmentos resultantes. Los segmentos invadidos tienen prioridad sobre cualquier otro tipo de refinamiento.

+ *Triángulos malos (_bad triangles_):* Un triángulo se considera malo si su ángulo mínimo es inferior al umbral solicitado o si su área supera el máximo configurado. En tal caso, se inserta un nuevo vértice en el circuncentro del triángulo, lo que garantiza su eliminación por la propiedad de Delaunay. Si este nuevo vértice resultara a su vez en la invasión de algún segmento, la inserción se revierte y los segmentos afectados se dividen.

// [ NOTA FIGURA — requiere citar fuente ]
// Aquí va la Figura 11 del paper @Shewchuk96, que ilustra la
// eliminación de un triángulo de mala calidad insertando un vértice
// en su circuncentro. Caption sugerido:
// [Eliminación de un triángulo de mala calidad mediante la inserción
// de un vértice en su circuncentro. Fuente: @Shewchuk96.]

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

// [ NOTA FIGURA — figura de Villarroel, citar explícitamente ]
// Considerar incluir la Figura 3.2 del informe @Villarroel23, que
// compara la URH original, la triangulación de Delaunay estándar, la
// CDT sin restricciones y la CDT con ángulo mínimo 20°. Esto ilustra
// de manera efectiva el efecto de los parámetros de triangulación.
// Caption: [Efecto de los parámetros de triangulación sobre una URH.
// (a) URH original, (b) Triangulación de Delaunay, (c) CDT sin
// restricciones de calidad, (d) CDT con ángulo mínimo 20°.
// Fuente: @Villarroel23.]
// Verifica si el reglamento de tu universidad exige permiso del autor
// para reproducir figuras de memorias de título previas.

Si bien esta estrategia permite obtener polígonos que satisfacen criterios geométricos configurables, el plugin de QGIS desarrollado en dicho trabajo presentó problemas de inestabilidad al ejecutar la librería Triangle directamente dentro del proceso de QGIS, provocando cierres inesperados del software en geometrías complejas @Villarroel23.

== Algoritmo Polylla

Por otro lado, Salinas et al. @Salinas22 propusieron el algoritmo Polylla, un método indirecto de generación de mallas poligonales que parte de una triangulación de entrada y produce una malla de polígonos sin insertar ni eliminar ningún vértice. El algoritmo se basa en el concepto de _regiones de arista terminal_ (_terminal-edge regions_) @Salinas22 y se divide en tres fases: etiquetado, recorrido y reparación.

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