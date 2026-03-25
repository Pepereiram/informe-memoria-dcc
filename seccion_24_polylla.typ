// =====================================================================
// SECCIÓN 2.4 — ALGORITMO POLYLLA
// Fuente primaria: @Salinas22 (Salinas et al., 2022, arXiv:2201.11925)
// =====================================================================

=== Algoritmo Polylla

Como alternativa a la estrategia de disolución, Salinas et al.
@Salinas22 propusieron el algoritmo Polylla, un método indirecto de
generación de mallas poligonales que parte de una triangulación de
entrada y produce una malla de polígonos sin insertar ni eliminar ningún
vértice. El algoritmo se basa en el concepto de _regiones de arista
terminal_ (_terminal-edge regions_) @Salinas22 y se divide en tres
fases: etiquetado, recorrido y reparación.

==== Conceptos fundamentales

El punto de partida es clasificar cada arista de la triangulación según
su longitud relativa en los dos triángulos que la comparten @Salinas22.
Esta clasificación produce tres tipos de aristas:

- *Arista terminal (_terminal-edge_):* es la arista más larga de los dos
  triángulos que la comparten simultáneamente. Estas aristas son la base
  estructural del algoritmo.

- *Arista frontera (_frontier-edge_):* no es la arista más larga de
  ninguno de los dos triángulos que la comparten. Las aristas frontera
  delimitan los polígonos finales.

- *Arista interna (_internal-edge_):* es la arista más larga de
  exactamente uno de los dos triángulos que la comparten.

A partir de este etiquetado se define la *región de arista terminal*: el
conjunto de todos los triángulos $t_i$ de la triangulación cuyo camino
de propagación de arista más larga (_Longest-Edge Propagation Path_ o
LEPP) comparte la misma arista terminal @Salinas22. Una propiedad clave
es que estas regiones cubren todo el dominio sin solapamiento, lo que
garantiza que la partición resultante sea una malla válida @Salinas22.

==== Las tres fases del algoritmo

*Fase 1 — Etiquetado (_Label Phase_):* Se itera sobre todos los
triángulos de la triangulación para identificar la arista más larga de
cada uno. En una segunda iteración sobre las aristas, se clasifica cada
una como terminal, frontera o interna según la definición anterior. Se
selecciona además un triángulo semilla por cada región de arista
terminal @Salinas22.

*Fase 2 — Recorrido (_Traversal Phase_):* Partiendo del triángulo
semilla de cada región, el algoritmo recorre los triángulos vecinos por
sus aristas internas y registra los vértices de las aristas frontera
en sentido antihorario para construir el polígono @Salinas22. El resultado
puede ser un polígono simple o un polígono no simple si la región
contiene aristas internas que actúan como barreras (_barrier-edges_).

*Fase 3 — Reparación (_Reparation Phase_):* Los polígonos no simples
son subdivididos en polígonos simples promoviendo algunas aristas
internas incidentes en los puntos extremos de las _barrier-edges_ a la
categoría de aristas frontera @Salinas22. Este paso es poco frecuente:
experimentalmente, menos del 1% de las regiones de arista terminal
generan polígonos no simples @Salinas22.

==== Complejidad computacional

Una ventaja central de Polylla frente a la estrategia de disolución es
su complejidad computacional. Salinas et al. @Salinas22 demostraron que
las tres fases del algoritmo tienen costo $O(m)$ cada una, siendo $m$ el
número de triángulos de la triangulación de entrada, con $m = O(n)$
donde $n$ es el número de puntos. Por lo tanto, la complejidad total del
algoritmo es $O(n)$ tanto en tiempo como en memoria @Salinas22.

Esto contrasta con la estrategia de disolución de Villarroel
@Villarroel23, cuyo proceso iterativo de fusión de triángulos depende de
la estructura de vecindad generada por la triangulación inicial. En el
peor caso, la disolución puede requerir revisar repetidamente el
conjunto de polígonos hasta que no sea posible ninguna fusión adicional
que respete los criterios geométricos, lo que puede escalar hasta
$O(n^3)$ en función del número de elementos.

==== Propiedades de las mallas generadas

Salinas et al. @Salinas22 compararon sistemáticamente las mallas de
Polylla con las mallas de Voronoi restringido, que son actualmente la
referencia estándar en mallas poligonales para métodos numéricos.
Los resultados muestran que, para el mismo conjunto de puntos de
entrada, las mallas de Polylla contienen aproximadamente tres veces
menos polígonos que las mallas de Voronoi, con un promedio de 6.5
triángulos por polígono y 8.5 vértices por polígono para más de $10^4$
puntos @Salinas22. Además, Polylla no requiere insertar nuevos puntos
ni en el interior del dominio ni en los bordes, a diferencia del
algoritmo de Voronoi restringido que introduce los puntos de Voronoi
@Salinas22.

En cuanto al tiempo de ejecución, la generación de una malla de Polylla
a partir de una triangulación de Delaunay existente es significativamente
más rápida que la generación de una malla de Voronoi restringido. Para
un millón de vértices, Polylla tarda aproximadamente 1.3 segundos frente
a los 21341 segundos del algoritmo de Voronoi usando Detri2, o los 991
segundos usando CGAL @Salinas22.

==== Relevancia para el problema hidrológico

En el contexto del presente trabajo, Polylla presenta varias
características que lo hacen especialmente adecuado como alternativa a
la estrategia de disolución para la generación de mallas de URHs:

En primer lugar, su complejidad lineal $O(n)$ garantiza tiempos de
ejecución predecibles y acotados, lo que es crítico para la automatización
del proceso dentro del entorno de QGIS, donde la inestabilidad del
tiempo de ejecución es uno de los problemas identificados @Villarroel23.

En segundo lugar, Polylla respeta exactamente el conjunto de puntos de
la triangulación de entrada sin añadir vértices adicionales @Salinas22.
Esto preserva la fidelidad geométrica de los bordes de las URHs, que
corresponden a contornos físicos significativos como límites de uso de
suelo, subcuencas o red de drenaje @Sanzana11.

En tercer lugar, el algoritmo es determinístico: dado el mismo conjunto
de puntos y la misma triangulación, produce siempre el mismo resultado
@Salinas22. Esto contrasta con la estrategia de disolución, cuyo
resultado depende del orden en que se procesan los triángulos vecinos
@Villarroel23, introduciendo variabilidad en la malla final.

Finalmente, Polylla es capaz de procesar geometrías complejas con
agujeros (_holes_) @Salinas22, lo que resulta relevante para cuencas
hidrológicas que incluyen islas o polígonos interiores, uno de los casos
problemáticos identificados originalmente por Sanzana @Sanzana11.

// [ NOTA BIBLIOGRÁFICA ]
// @Salinas22 corresponde a: Salinas, S., Hitschfeld-Kahler, N.,
// Ortiz-Bernardin, A., y Si, H. (2022). POLYLLA: Polygonal meshing
// algorithm based on terminal-edge regions. arXiv:2201.11925v2.
// Verifica si ya está publicado en revista con DOI definitivo
// antes de fijar la cita en tu .bib.
