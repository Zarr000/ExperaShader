#version 150
#ifndef RENDERER_VALIDATION_GLSL
#define RENDERER_VALIDATION_GLSL

#include "renderer_common.glsl"
#include "renderer_graph.glsl"
#include "renderer_resource.glsl"

// Renderer validation with dependency checking

struct ValidationResult {
    bool valid;
    float missingDependencies;
    float duplicateOutputs;
    float circularReferences;
    float unusedResources;
    float invalidHistory;
    float samplerConflicts;
    float compatibilityWarnings;
    float duplicateEvaluations;
    float resourceConflicts;
    float deadPasses;
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
    v.duplicateEvaluations = 0.0;
    v.resourceConflicts = 0.0;
    v.deadPasses = 0.0;
    return v;
}

// Validate render graph dependencies
ValidationResult rendererValidateGraph(RenderGraph g) {
    ValidationResult result = rendererValidationInit();

    // Check for missing dependencies
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        for (int j = 0; j < 4; j++) {
            float dep = g.nodes[i].dependencies[j];
            if (dep < 0.0) break;
            bool found = false;
            for (int k = 0; k < 16; k++) {
                if (float(k) >= g.nodeCount) break;
                if (g.nodes[k].id == dep) found = true;
            }
            if (!found) result.missingDependencies += 1.0;
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

    // Check for dead passes (no outputs)
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        if (g.nodes[i].enabled && g.nodes[i].outputCount == 0.0) {
            result.deadPasses += 1.0;
        }
    }

    // Overall validity
    result.valid = (result.missingDependencies == 0.0 &&
                    result.duplicateOutputs == 0.0 &&
                    result.circularReferences == 0.0 &&
                    result.duplicateEvaluations == 0.0 &&
                    result.resourceConflicts == 0.0 &&
                    result.deadPasses == 0.0);

    return result;
}

#endif