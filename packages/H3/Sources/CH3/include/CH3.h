// CH3.h
// Umbrella header for SwiftPM C target.
//

// MARK: - CORE HEADERS:
#include "h3api.h"  // Public API -- all functions for Swift or C are declared here.
#include "h3Index.h"  // Defines H3Index and supporting utilities.
#include "latLng.h"  // Functions for converting between degrees/radian and geographic coordinates.
// #include "linkedGeo.h"  // Defines the LinkedGeoPolygon structure used for converting hexagon sets into polygons.
// #include "polyfill.h"  // Implements polygonToCells() logic -- fills a polygon with hexagons.
// #include "polygon.h"  // Polygon structs like GeoPolygon and polygon-related functions.
// #include "polygonAlgos.h"  // Algorithms that support polygon filling, boundary tracing, etc.

// MARK: - GEOMETRY & COORDINATE SYSTEMS:
// #include "bbox.h"  // Bounding box calculations for polygons.
// #include "coordijk.h"  // Defines the IJ (hexagonal grid) coordinate system.
// #include "faceijk.h"  // Handles face-IJK projection; projecting a hexagon onto an icosahedron face.
// #include "localij.h"  // Converts between H3Index and local IJ coordinates.

// Basic vector math for 2D and 3D coordinates.
// #include "vec2d.h"
// #include "vec3d.h"

// Functions and structs for working with cell vertices.
// #include "vertex.h"
// #include "vertexGraph.h"

// MARK: - MATHEMATICAL OPERATIONS:
// #include "alloc.h"  // Memory-safe allocation wrappers.
// #include "constants.h"  // Math constants, angle conversions, etc.
// #include "mathExtensions.h"  // Common math functions.

// MARK: - SUPPORT LOGIC:
// #include "algos.h"  // Algorithms for hexgonal grid traversals.
// #include "baseCells.h"  // Maps base cell numbers to faces and orientations.
// #include "directedEdge.h"  // Code for creating & inspecting directed edges between cells.
// #include "h3Assert.h"  // Internal debugging asserts.
// #include "iterators.h"  // Helpers for iterating over child/parent hexagons, etc.
