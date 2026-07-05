#version 150
#ifndef RENDERER_SSGI_STATS_GLSL
#define RENDERER_SSGI_STATS_GLSL
#include renderer_ssgi_optimizer.glsl
struct SSGIStats { float rays; float steps; float fetches; float cost; };
SSGIStats rendererSSGIStatsInit() { SSGIStats s; s.rays=0.0; s.steps=0.0; s.fetches=0.0; s.cost=0.0; return s; }
void rendererSSGIStatsAccumulate(inout SSGIStats s, SSGIOptimizationState o) { s.rays+=o.rayCount; s.steps+=o.stepCount; s.fetches+=o.fetchCount; s.cost+=o.estimatedCost; }
#endif
