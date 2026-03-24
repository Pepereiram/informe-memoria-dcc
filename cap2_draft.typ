// =====================================================================
// CAPÍTULO 2 — FUNDAMENTOS Y ESTADO DEL ARTE
// Draft con anotaciones editoriales [ NOTA: ... ]
// =====================================================================

= Fundamentos y Estado del Arte

// =====================================================================
== Triangulaciones
// =====================================================================

Una triangulación de un conjunto de puntos $S$ en el plano es una
subdivisión del área delimitada por la envoltura convexa de $S$ en un
conjunto maximal de triángulos que se intersecan únicamente en vértices
y aristas compartidas. En el contexto del modelamiento numérico, estas
estructuras sirven para discretizar dominios continuos en elementos
finitos procesables por algoritmos computacionales.

Una de las triangulaciones estándar al día de hoy es la Triangulación
de Delaunay. Esta se define como la triangulación tal que el círculo
circunscrito de cada triángulo no contiene ningún otro punto del
conjunto de entrada en su interior. Esta propiedad garantiza que se
maximice el ángulo mínimo de todos los triángulos, evitando en la
medida de lo posible la generación de triángulos degenerados o "delgados".

// [ NOTA FIGURA — no requiere permiso especial ]
// Aquí va la figura comparativa de círculos circunscritos.
// Fuente recomendada: Wikipedia (dominio público / CC-BY-SA).
// Etiqueta sugerida: #figure(..., caption: [Comparación entre una
// triangulación no-Delaunay (izquierda) y la Triangulación de Delaunay
// (derecha). En la versión Delaunay ningún círculo circunscrito
// contiene puntos del conjunto ajenos al triángulo que lo define.
// Adaptado de @WikiDelaunay.])
// Agrega la entrada bibliográfica correspondiente a Wikipedia si la usas.

Cuando el dominio incluye fronteras físicas o restricciones geométricas
---como los bordes de una cuenca hidrológica--- se recurre a la
Triangulación de Delaunay con Restricciones (_Constrained Delaunay
Triangulation_, CDT). A diferencia de la versión estándar, la CDT
admite segmentos de entrada que deben aparecer obligatoriamente como
aristas de la malla final, incluso si esto implica no satisfacer
localmente la condición de Delaunay en las inmediaciones de dichos
segmentos.

// [ NOTA FIGURA — requiere citar fuente ]
// Aquí va la Figura 9 del paper de Shewchuk @Shewchuk96, que muestra
// la CDT y la malla refinada resultante (guitarra con ángulo mín. 20°).
// Como es una figura de un paper publicado, cítala explícitamente:
// caption: [Triangulación de Delaunay con Restricciones y posterior
// refinamiento con ángulo mínimo de 20°. Fuente: @Shewchuk96.]
// Verifica con tu universidad si basta la cita o si necesitas permiso
// del autor para reproducirla en un trabajo publicado en biblioteca.

// ---------------------------------------------------------------------
=== La librería Triangle
// ---------------------------------------------------------------------

La librería Triangle @Shewchuk96 es la implementación de referencia
en la investigación académica para la generación de mallas de Delaunay
en dos dimensiones. Su núcleo es el algoritmo de Refinamiento de
Delaunay de Ruppert @Ruppert95, el cual permite construir mallas de
"calidad garantizada", entendida como la ausencia de triángulos con
ángulos menores a un umbral definido por el usuario.

// [ NOTA CITA ]
// @Ruppert95 corresponde a: Ruppert, J. (1995). A Delaunay refinement
// algorithm for quality 2-dimensional mesh generation. Journal of
// Algorithms, 18(3), 548–585. Agrégala a tu archivo .bib si no la
// tienes aún; es la fuente primaria del algoritmo, distinta de @Shewchuk96.

El proceso parte de una CDT del dominio de entrada y procede de forma
iterativa insertando vértices adicionales —denominados puntos de
Steiner— hasta que la malla satisface las restricciones de calidad
solicitadas @Shewchuk96. La inserción de estos puntos se rige por dos
reglas de prioridad:

+ *Invasión de segmentos (_encroachment_):* Se dice que un segmento es
  "invadido" si algún vértice de la malla cae dentro de su círculo
  diametral (el menor círculo que lo contiene). Cuando esto ocurre, el
  segmento se divide insertando un vértice en su punto medio,
  reduciendo así el radio del círculo diametral de los subsegmentos
  resultantes. Los segmentos invadidos tienen prioridad sobre cualquier
  otro tipo de refinamiento.

+ *Triángulos de mala calidad (_bad triangles_):* Un triángulo se
  considera de mala calidad si su ángulo mínimo es inferior al umbral
  solicitado o si su área supera el máximo configurado. En tal caso, se
  inserta un nuevo vértice en el circuncentro del triángulo, lo que
  garantiza su eliminación por la propiedad de Delaunay. Si este nuevo
  vértice resultara a su vez en la invasión de algún segmento, la
  inserción se revierte y los segmentos afectados se dividen
  preferentemente.

// [ NOTA FIGURA — requiere citar fuente ]
// Aquí va la Figura 11 del paper @Shewchuk96, que ilustra la
// eliminación de un triángulo de mala calidad insertando un vértice
// en su circuncentro. Caption sugerido:
// [Eliminación de un triángulo de mala calidad mediante la inserción
// de un vértice en su circuncentro. Fuente: @Shewchuk96.]

Ruppert @Ruppert95 demostró que este procedimiento converge para
restricciones de ángulo mínimo de hasta 20.7°, y en la práctica
Triangle opera de manera confiable con ángulos de hasta 33°
@Shewchuk96. El usuario controla la calidad de la malla mediante dos
parámetros principales: el ángulo mínimo permitido y el área máxima
de los triángulos.

// =====================================================================
== Simulación Hidrológica y Unidades de Respuesta Hidrológica (URH)
// =====================================================================

// [ PLACEHOLDER — pendiente hasta tener acceso a @Sanzana12 y fuentes
//   de Flügel 1995. Contenido a desarrollar: definición de PUMMA,
//   definición de URH, por qué los polígonos deben cumplir criterios
//   geométricos, descriptores de forma (FF, C, SI, CI) con fórmulas.
//   Todo el contenido de esta sección debe citarse a @Sanzana12 y
//   @Villarroel23 según corresponda. ]

El modelamiento de cuencas requiere... @Sanzana12.

// =====================================================================
== Estrategias de Generación de Mallas Poligonales
// =====================================================================

Dado que la triangulación directa de una URH produce un número excesivo
de polígonos triangulares que incrementan el costo computacional del
modelo hidrológico y reducen la representatividad de la malla
@Villarroel23, se han propuesto estrategias que parten de una
triangulación de calidad y la transforman en una malla de polígonos
más compacta. A continuación se describen las dos estrategias relevantes
para este trabajo.

// ---------------------------------------------------------------------
=== Estrategia de Disolución
// ---------------------------------------------------------------------

El trabajo de Villarroel @Villarroel23 propuso un método de dos etapas
para mejorar las URHs de mala calidad geométrica. En la primera etapa
se genera una CDT de calidad sobre el polígono de entrada, utilizando
la librería Triangle con parámetros configurables de ángulo mínimo y
área máxima. Esto asegura que los triángulos resultantes tengan una
distribución uniforme y eviten ángulos degenerados @Villarroel23.

En la segunda etapa se aplica un proceso de disolución iterativa sobre
la triangulación obtenida. El algoritmo recorre los triángulos de la
malla y fusiona cada uno con el vecino adyacente de mayor área, siempre
que el polígono resultante de la fusión satisfaga el descriptor de forma
umbral definido por el usuario. Este proceso se repite hasta que ninguna
fusión adicional sea posible sin violar las restricciones geométricas
@Villarroel23.

Los descriptores de forma implementados para controlar la disolución son
los siguientes @Villarroel23:

- *Factor de Forma:* $F F = (4 pi A) / P^2$
- *Compacidad:* $C = sqrt(4 pi A) / P$
- *Índice de Solidez:* $S I = A / A_"conv"$
- *Índice de Convexidad:* $C I = P_"conv" / P$

donde $A$ y $P$ son el área y el perímetro del polígono, y $A_"conv"$
y $P_"conv"$ corresponden al área y al perímetro de su cerradura
convexa. Todos los índices toman valores en $(0, 1]$, siendo $1$ el
valor correspondiente a un polígono perfectamente convexo (o circular,
para $FF$ y $C$) @Villarroel23.

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

Si bien esta estrategia permite obtener polígonos que satisfacen
criterios geométricos configurables, el plugin de QGIS desarrollado
en dicho trabajo presentó problemas de inestabilidad al ejecutar la
librería Triangle directamente dentro del proceso de QGIS,
provocando cierres inesperados del software en geometrías complejas
@Villarroel23.

// ---------------------------------------------------------------------
=== Algoritmo Polylla
// ---------------------------------------------------------------------

// [ PLACEHOLDER — pendiente hasta tener acceso a @Salinas22. ]
Como alternativa, el algoritmo Polylla @Salinas22 utiliza regiones de
arista terminal...

// =====================================================================
== Sistemas de Información Geográfica (SIG)
// =====================================================================

Un Sistema de Información Geográfica (SIG) es un sistema computacional
diseñado para capturar, almacenar, manipular, analizar y desplegar
información georeferenciada, con el fin de apoyar la resolución de
problemas complejos de planificación y gestión territorial
@Villarroel23. En el contexto de la modelación hidrológica, el uso de
un SIG resulta necesario por el volumen de información geoespacial que
debe ser gestionada, y porque permite representar los elementos del
territorio tanto en formato ráster como vectorial @Villarroel23.

En la representación *vectorial*, los objetos geográficos se codifican
como puntos, líneas o polígonos. En la representación *ráster*, el
territorio se divide en una grilla de píxeles, cada uno con el valor
de la propiedad que se desea modelar. Para la representación de URHs
se emplea exclusivamente el modelo vectorial, ya que las unidades de
respuesta hidrológica son por definición polígonos irregulares
@Villarroel23.

// ---------------------------------------------------------------------
=== QGIS y el ecosistema PyQGIS
// ---------------------------------------------------------------------

QGIS es una plataforma de código abierto para sistemas de información
geográfica, ampliamente utilizada en investigación académica y en
aplicaciones industriales. Su arquitectura permite extender las
funcionalidades del software mediante _plugins_ escritos en Python,
a través de la API PyQGIS @Villarroel23. Este entorno proporciona
acceso a librerías geoespaciales como GDAL/OGR para la manipulación
de capas vectoriales y ráster.

Sin embargo, la ejecución de código externo intensivo dentro del proceso
de QGIS presenta restricciones relevantes en la gestión de memoria y
en el manejo de subprocesos. En particular, la invocación directa de
librerías compiladas en C —como Triangle— dentro del mismo espacio de
memoria del proceso principal de QGIS puede provocar errores de
segmentación y cierres inesperados del software, especialmente al
procesar geometrías complejas o mallas de gran tamaño @Villarroel23.
Esta limitación constituye uno de los problemas centrales que motiva
el rediseño de la arquitectura del plugin abordado en el presente
trabajo.
