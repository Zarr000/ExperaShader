# Expera Shader — Engineering Report (Release Candidate)

## Architecture Overview

Expera Shader implements a modern, production-quality rendering architecture with unified optimization across all subsystems.

### Renderer Core V2 Components

| Component | Location | Purpose |
|-----------|----------|---------|
| Render Graph | lib/renderer/renderer_graph.glsl | Node-based execution scheduling |
| Resource Lifetime | lib/renderer/renderer_resource.glsl | GPU resource allocation tracking |
| History Pool | lib/renderer/renderer_history.glsl | Temporal texture management |
| GPU Budget Manager | lib/renderer/renderer_budget.glsl | Adaptive quality scaling |
| Shared Sampling | lib/renderer/renderer_sampling.glsl | Blue noise/Halton/Poisson sequences |
| GPU Statistics | lib/renderer/renderer_metrics.glsl | Performance tracking |
| GPU Profiler | lib/renderer/renderer_profiler.glsl | Timing instrumentation |
| Memory Manager | lib/renderer/renderer_memory.glsl | VRAM optimization |

## Subsystem Optimizations

### Atmosphere Engine V2 (Production Ready)

**File:** `lib/render_atmosphere_optimizer.glsl`

Optimization Phases:
1. **Frame Context** - Single evaluation of sun/moon/altitude/state
2. **Density Cache** - Cached Rayleigh/Mie/Ozone densities
3. **Optical Depth Cache** - Cached view/sun/moon optical depths
4. **Transmittance Cache** - Cached atmospheric transmittance
5. **Sky LUT Cache** - Runtime-updated sky lookup table
6. **Adaptive Scattering Budget** - Quality/dynamic scaling
7. **Adaptive Multiple Scattering** - Iteration count based on conditions
8. **Shared Lighting Cache** - Sun/Moon radiance reuse
9. **Adaptive Sampling** - 8-48 samples based on quality/budget

### Water Renderer V2 (Production Ready)

**File:** `lib/render_water_optimizer.glsl`

Optimization Phases:
1. **Frame Context** - Shared position/normal/directions
2. **Reflection Cache** - SSR/Sky/Cloud reflection reuse
3. **Refraction Cache** - Cached refraction color/depth
4. **Shared Lighting Cache** - Atmosphere lighting integration
5. **Adaptive Reflection Budget** - 2-24 samples based on conditions
6. **Adaptive Refraction Budget** - Water depth/distortion scaling
7. **Wave Evaluation Cache** - Gerstner wave reuse
8. **Foam Cache** - Cached foam density/coverage
9. **Caustics Optimization** - Adaptive caustics sampling

## Quality Presets

Location: `lib/profiles/presets.glsl`

| Preset | LUT Resolution | Samples | Multiple Scattering | Raymarch |
|--------|---------------|---------|-------------------|----------|
| Performance | 32 | 2-4 | 0.3 | 2 |
| Balanced | 64 | 4-6 | 0.6 | 4 |
| High | 96 | 6-12 | 0.8 | 6 |
| Ultra | 128 | 12-16 | 1.0 | 8 |
| Extreme | 192 | 16-24 | 1.2 | 12 |

## Shared Frame Context Pattern

Every subsystem follows the unified pattern:
```glsl
// Phase 1: Frame Context (once per frame)
SubsystemFrameContext context = subsystemComputeFrameContext(...);

// Phase 2: Cache Lookup (avoid duplicate work)
vec4 cached = subsystemGetCachedValues(cache, ...);

// Phase 3: Adaptive Evaluation
float samples = subsystemAdaptiveSamples(quality, conditions, budget);

// Phase 4: Record Statistics
subsystemRecordStats(metrics, ...);
```

## Cache Ownership

| Cache Type | Owner | Consumers |
|------------|-------|-----------|
| Atmosphere Density | Atmosphere Engine | Clouds, Water, Deferred |
| Atmosphere Optical Depth | Atmosphere Engine | Clouds, Water |
| Atmosphere Transmittance | Atmosphere Engine | All lighting passes |
| Atmosphere Lighting | Atmosphere Engine | Water, Clouds, Shadows |
| Water Reflection | Water Engine | Composite |
| Water Refraction | Water Engine | Composite |
| SSR Result | SSR Engine | SSGI, Deferred |
| Shadow Mask | Shadow Engine | All lighting |

## Performance Targets

| Metric | Target Improvement |
|--------|------------------|
| Density Evaluations | 20-40% reduction |
| Optical Depth | 25-45% reduction |
| Transmittance | 20-35% reduction |
| LUT Updates | 20-40% reduction |
| VRAM Usage | 15-30% reduction |
| Texture Fetches | 20-35% reduction |
| GPU Barriers | 20-35% reduction |

## Validation Checklist

- [x] No placeholder implementations
- [x] No duplicated logic
- [x] No duplicated texture fetches
- [x] No duplicated material decoding
- [x] No duplicated atmosphere evaluation
- [x] No duplicated weather evaluation
- [x] Unified Renderer Core ownership
- [x] Resource Lifetime validated
- [x] History Pool validated
- [x] GPU Budget validated
- [x] Shared Sampling validated
- [x] GPU Statistics validated
- [x] Debug Framework validated
- [x] Memory validated
- [x] Production-ready architecture

## Compatibility

- Minecraft 1.21.11+
- Iris (Shader Implementation)
- OptiFine (Alternative)

## Files Modified

- `lib/render_atmosphere_optimizer.glsl` (NEW)
- `lib/render_water_optimizer.glsl` (NEW)
- `lib/renderer/renderer_optimizer.glsl` (NEW)
- `lib/atmosphere/atmosphere_density.glsl` (enhanced)
- `lib/atmosphere/atmosphere_mie.glsl` (enhanced)
- `lib/atmosphere/atmosphere_ozone.glsl` (NEW)
- `lib/atmosphere/atmosphere_moon.glsl` (fixed)

---

*Expera Shader v1.0 Release Candidate*