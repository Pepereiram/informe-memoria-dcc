// =====================================================================
// SECCIÓN 2.2 — SIMULACIÓN HIDROLÓGICA Y UNIDADES DE RESPUESTA
// HIDROLÓGICA (URH)
// Fuentes primarias: @Sanzana11 y @Villarroel23
// =====================================================================

== Simulación Hidrológica y Unidades de Respuesta Hidrológica (URH)

La modelación hidrológica distribuida de cuencas peri-urbanas requiere
definir con precisión la unidad espacial que representa el territorio.
La discretización del espacio en unidades homogéneas determina tanto la
calidad de la representación física como la estabilidad numérica del
modelo @Sanzana11. A diferencia de los modelos basados en grillas
regulares, los modelos vectoriales permiten representar elementos de
tamaño variable y preservar barreras hidrológicas naturales y
artificiales ---calles, canales y colectores--- que modifican
significativamente la dirección del flujo superficial @Sanzana11.

En este contexto, el modelo hidrológico distribuido PUMMA (_Peri-Urban
Model for landscape MAnagement_) @Sanzana11 basa su representación
espacial en un enfoque vectorial que combina dos tipos de unidades: los
Elementos Hidrológicos Urbanos (EHU) para zonas urbanas y las Unidades
de Respuesta Hidrológica (URH) para zonas peri-urbanas y naturales.

=== Unidades de Respuesta Hidrológica

El concepto de Unidades de Respuesta Hidrológica fue propuesto por
Flügel @Flugel95 y se ha aplicado ampliamente en la modelación de
cuencas mediante distintos modelos hidrológicos distribuidos @Sanzana11.
Una URH es una unidad espacial que representa un sector del territorio
con propiedades físicas homogéneas de evaporación, infiltración,
rugosidad y dirección de flujo @Sanzana11. El supuesto fundamental es
que la dinámica de los procesos hidrológicos al interior de cada URH
debe ser menor que la dinámica de los procesos entre diferentes URHs
@Sanzana11.

// [ NOTA CITA ]
// @Flugel95 corresponde a: Flügel, W.A. (1995). Delineating
// hydrological response units by geographical information system
// analyses for regional hydrological modelling using PRMS/MMS in the
// Drainage Basin of the River Bröl, Germany. Hydrological Processes,
// 9(3–4), 423–436. Agrega esta entrada a tu archivo .bib.

Las URHs se obtienen como resultado de la intersección de distintas
capas vectoriales de información geográfica. Las capas de polígonos
corresponden a los mapas de uso de suelo, tipo de suelo, sub-cuencas
y geología, mientras que las capas de polilíneas se asocian a la
información de ríos, canales artificiales y colectores de aguas lluvias
@Sanzana11. El resultado es un conjunto de polígonos simples de forma
irregular que representan sectores con características homogéneas
relevantes para el ciclo hidrológico.

=== Requerimientos geométricos de la malla

Para que el modelo PUMMA pueda calcular correctamente los flujos entre
unidades adyacentes, la malla de URHs debe satisfacer requisitos
topológicos y numéricos precisos @Sanzana11. Específicamente, el cálculo
del flujo lateral entre dos unidades se realiza mediante la Ley de Darcy,
en la que el caudal de descarga depende, entre otros factores, de la
distancia entre los centros de gravedad de los polígonos adyacentes
@Sanzana11. Esto implica que si el centroide de un polígono se encuentra
fuera de su propio contorno ---situación que ocurre en polígonos muy
cóncavos o alargados--- la distancia calculada no tiene representación
física real y los cálculos de flujo resultan incorrectos @Sanzana11.

Adicionalmente, la longitud de las interfaces entre polígonos vecinos
incide directamente en la estimación del flujo superficial, por lo que
polígonos con perímetros sobreestimados ---como los que resultan de
digitalizaciones con exceso de vértices--- afectan la calidad de los
resultados del modelo @Sanzana11.

En consecuencia, para una correcta aplicación del modelo es necesario
corregir aquellos elementos mal formados de la malla de entrada, que
corresponden a polígonos con centroides fuera del polígono, bordes mal
representados, área excesiva, o alta variabilidad interna de alguna
propiedad física como la pendiente @Sanzana11.

=== Descriptores de forma

Para identificar de manera sistemática los polígonos que no satisfacen
los criterios geométricos del modelo, Sanzana @Sanzana11 propuso el uso
de descriptores de forma. Estos son índices numéricos que caracterizan
la geometría de un polígono en función de la distribución de su área y
su perímetro @Sanzana11. En la Tabla siguiente se muestran los cuatro
descriptores considerados @Sanzana11:

// [ NOTA TABLA ]
// Puedes presentar esto como una tabla en Typst. Los valores de
// referencia son todos de @Sanzana11, quien los toma de Russ (1995).
// Considera agregar @Russ95 como cita secundaria si tienes acceso.

#table(
  columns: (auto, auto, auto),
  align: (left, center, left),
  table.header([*Descriptor*], [*Expresión*], [*Descripción*]),
  [Factor de Forma],
  [$F F = (4 pi A) / P^2$],
  [Mide la similitud con un círculo a través de área y perímetro],
  [Compacidad],
  [$C = sqrt(4 pi A) / P$],
  [Variante del factor de forma, menos sensible a polígonos pequeños],
  [Índice de Solidez],
  [$S I = A / A_"conv"$],
  [Cociente entre el área del polígono y la de su cerradura convexa],
  [Índice de Convexidad],
  [$C I = P_"conv" / P$],
  [Cociente entre el perímetro de la cerradura convexa y el del polígono],
)

Donde $A$ y $P$ son el área $["L"^2]$ y el perímetro $["L"]$ del
polígono, y $A_"conv"$ y $P_"conv"$ corresponden al área y al perímetro
de su cerradura convexa, respectivamente @Sanzana11. Todos los índices
toman valores en $(0, 1]$, siendo $1$ el valor correspondiente a un
polígono perfectamente convexo.

El Factor de Forma y la Compacidad permiten identificar polígonos
delgados y alargados, siendo el Factor de Forma más sensible a elementos
de área pequeña @Sanzana11. Los Índices de Solidez y Convexidad cuantifican
el grado de convexidad comparando el polígono con su cerradura convexa:
el Índice de Convexidad, al basarse en perimetros, resulta más sensible
que el Índice de Solidez en polígonos con contornos muy irregulares que
aumentan el perímetro sin aumentar el área @Sanzana11.

Mediante un análisis de sensibilidad aplicado sobre las cuencas Mercier
y Chaudanne de Lyon, Francia, Sanzana @Sanzana11 determinó empíricamente
que el Índice de Convexidad es el descriptor más adecuado para
identificar polígonos mal formados, estableciendo un valor límite de
$C I = 0.75$ por encima del cual un polígono se considera bien formado
para el modelo hidrológico.

// [ NOTA SOBRE CITAS ]
// Toda la información de esta sección proviene de @Sanzana11 (tesis de
// magíster de Pedro Sanzana, diciembre 2011). Al citar, usa el año
// correcto según tu .bib: el documento es de diciembre 2011.
// Tu clave de cita puede ser @Sanzana11 o @Sanzana12 si la usas
// en base al año de registro oficial en la biblioteca.
// Verifica con tu profesora cuál año usar.
