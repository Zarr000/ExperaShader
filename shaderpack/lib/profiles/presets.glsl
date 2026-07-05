#version 150

#ifndef PROFILES_PRESETS_GLSL
#define PROFILES_PRESETS_GLSL

// Quality presets for atmosphere and rendering systems
// Maps to atmosphereQuality uniform values:
// 0.0 = Performance
// 1.0 = Balanced
// 2.0 = High
// 3.0 = Ultra
// 4.0 = Extreme

#define PRESET_PERFORMANCE 0.0
#define PRESET_BALANCED    1.0
#define PRESET_HIGH        2.0
#define PRESET_ULTRA       3.0
#define PRESET_EXTREME     4.0

// LUT resolution presets
#define LUT_RES_PERFORMANCE 32.0
#define LUT_RES_BALANCED    64.0
#define LUT_RES_HIGH        96.0
#define LUT_RES_ULTRA       128.0
#define LUT_RES_EXTREME     192.0

// Sample count presets
#define SAMPLES_PERFORMANCE 2.0
#define SAMPLES_BALANCED    4.0
#define SAMPLES_HIGH        6.0
#define SAMPLES_ULTRA       8.0
#define SAMPLES_EXTREME     12.0

// Multi-scattering quality presets
#define MS_PERFORMANCE 0.3
#define MS_BALANCED    0.6
#define MS_HIGH        0.8
#define MS_ULTRA       1.0
#define MS_EXTREME     1.2

// Optical depth quality presets
#define OD_PERFORMANCE 1.0
#define OD_BALANCED    2.0
#define OD_HIGH        3.0
#define OD_ULTRA       4.0
#define OD_EXTREME     6.0

// Raymarch quality presets
#define RM_PERFORMANCE 2.0
#define RM_BALANCED    4.0
#define RM_HIGH        6.0
#define RM_ULTRA       8.0
#define RM_EXTREME     12.0

#endif