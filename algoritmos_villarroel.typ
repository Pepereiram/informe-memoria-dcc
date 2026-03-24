// Requiere en tu documento:
// #import "@preview/algo:0.3.4": algo, i, d, comment, code
//
// Pega este bloque donde necesites las figuras.
// Ajusta el número de figura y el caption según tu esquema de numeración.

// ─────────────────────────────────────────────────────────────
// ALGORITMO 1 — Triangle Features
// ─────────────────────────────────────────────────────────────

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
    Algoritmo de triangulación de _features_ utilizando la librería
    Triangle. Basado en @Villarroel23.
  ],
) <alg-triangle-features>


// ─────────────────────────────────────────────────────────────
// ALGORITMO 2 — Build Neighbours
// ─────────────────────────────────────────────────────────────

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
    Algoritmo de construcción del grafo de vecindad entre triángulos.
    Basado en @Villarroel23.
  ],
) <alg-build-neighbours>


// ─────────────────────────────────────────────────────────────
// ALGORITMO 3 — Dissolve Features
// ─────────────────────────────────────────────────────────────
// (Contenido reconstruido desde la descripción en @Villarroel23,
//  sección 4.3. Verifica contra el Algoritmo 3 original.)

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
    $italic("dissolved") <- italic("False")$ \
    *for* $italic("feature")$ *in* $italic("dictFeatures")$ *do* #i \
      *if* $italic("feature")$ *is well shaped* *then* #i \
        *continue* #d \
      $italic("bestNeighbour") <- $ neighbour of $italic("feature")$
        with largest area \
      $italic("merged") <- $ Union$(italic("feature"),
        italic("bestNeighbour"))$ \
      *if* shape$(italic("merged")) >= italic("shapeThreshold")$
        *and* area$(italic("merged")) <= italic("maxArea")$ *then* #i \
        Replace $italic("feature")$ and $italic("bestNeighbour")$
          with $italic("merged")$ in $italic("dictFeatures")$ \
        Update $italic("dictNeighbours")$ \
        $italic("dissolved") <- italic("True")$ #d \
    #d \
    *if* $italic("dissolved")$ *then* #i \
      Recurse with updated $italic("dictFeatures")$ #d \
    *Return* $italic("dictFeatures")$
  ],
  caption: [
    Algoritmo de disolución iterativa de triángulos en polígonos que
    satisfacen restricciones geométricas. Basado en @Villarroel23.
  ],
) <alg-dissolve-features>
