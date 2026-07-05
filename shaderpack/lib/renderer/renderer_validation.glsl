#version 150
#ifndef RENDERER_VALIDATION_GLSL
#define RENDERER_VALIDATION_GLSL

#include "renderer_common.glsl"
#include "renderer_graph.glsl"
#include "renderer_resource.glsl"

// Renderer validation system

// Validation result structure
struct ValidationResult {
    bool valid;
    float missingDependencies;
    float duplicateOutputs;
    float circularReferences;
    float unusedResources;
    float invalidHistory;
    float samplerConflicts;
    float compatibilityWarnings;
};

// Initialize validation result
ValidationResult rendererValidationInit() {
    ValidationResult v;
    v.valid = true;
    v.missingDependencies = 0.0;
    v.duplicateOutputs = 0.0;
    v.circularReferences = 0.0;
    v.unusedResources = 0.0;
    v.invalidHistory = 0.0;
    v.samplerConflicts = 0.0;
    v.compatibilityWarnings = 0.0;
    return v;
}

// Validate render graph
ValidationResult rendererValidateGraph(RenderGraph g) {
    ValidationResult result = rendererValidationInit();

    // Check for missing dependencies
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        if (g.nodes[i].inputCount > 0 && !g.nodes[i].enabled) {
            result.missingDependencies += 1.0;
        }
    }

    // Check for duplicate outputs
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        if (g.nodes[i].outputCount > 2.0) {
            result.duplicateOutputs += 1.0;
        }
    }

    // Check for unused resources
    for (int i = 0; i < 32; i++) {
        if (float(i) >= g.resourceCount) break;
        bool used = false;
        for (int j = 0; j < 16; j++) {
            if (float(j) >= g.nodeCount) break;
            if (g.nodes[j].enabled) used = true;
        }
        if (!used) result.unusedResources += 1.0;
    }

    // Overall validity
    result.valid = (result.missingDependencies == 0.0 &&
                    result.duplicateOutputs == 0.0 &&
                    result.circularReferences == 0.0);

    return result;
}

#endif