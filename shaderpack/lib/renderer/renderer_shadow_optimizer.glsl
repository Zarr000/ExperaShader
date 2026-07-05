#version 150
#ifndef RENDERER_SHADOW_OPTIMIZER_GLSL
#define RENDERER_SHADOW_OPTIMIZER_GLSL
#include renderer_common.glsl
struct ShadowOpt{float pcf;float pcss;float contact;float bias;}
ShadowOpt rendererShadowOptInit(float q){ShadowOpt s;s.pcf=3.0;s.pcss=8.0;s.contact=4.0;s.bias=1.0;return s;}
#endif
