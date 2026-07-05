# Photorealistic AAA Minecraft Shader Pack

A fully original, physically-based Minecraft Java shader pack targeting Iris + OptiFine pipelines.

## Features

- Deferred-style lighting with GGX PBR (metallic/roughness workflow)
- GTAO-inspired SSAO with blue-noise rotation
- HDR tone mapping (ACES Filmic) + bloom pre/post stages
- TAA / FXAA post-processing passes
- Depth-based atmosphere and volumetric fog passes
- Procedural volumetric cloud coverage and cloud shadow factor (early integration)

> Note: This repository is a first production-grade implementation foundation. Some advanced systems (full SSR ray marching, CSM/PCSS, water optics/caustics, dynamic weather integration, etc.) are not fully wired/validated for every loader configuration yet.

## Screenshots

Add screenshots once the pack is integrated into a target Minecraft build.

## Compatibility

- Minecraft Java Edition (latest stable)
- Iris Shaders
- OptiFine

## Folder Structure

- `shaderpack/` - shaderpack root
- `shaderpack/lib/` - shared GLSL libraries
- `shaderpack/*` - pass entry shaders

## Performance Presets

Controlled via shader uniforms / properties and mapped by the loader.

- Low / Medium / High / Ultra

## Requirements

- Iris or OptiFine installed for Minecraft
- GPU supporting GLSL 1.50 (typical for modern Iris setups)

## License

MIT

## Credits

Original shader implementation by this repository.

## Development Roadmap

- Full SSR ray-marching + temporal reprojection
- Cascaded shadow maps + contact shadows
- Physically-based sky model (multi-order Rayleigh/Mie)
- Water optics (Fresnel, refraction approximation, caustics + foam)
- Dynamic weather + lightning
- Wet surface rendering + rain puddles
- Improved TAA resolve (motion vectors)
- Exposure histogram + film grain + LUT color grading

## Known Limitations

- Loader integration may require additional pass wiring depending on Iris/OptiFine version.
- Some advanced systems included as partial passes may require further hookup.

