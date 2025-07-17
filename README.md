# QGIS SAGA NextGen Docker Container

A containerized environment for geospatial analysis combining QGIS with SAGA GIS processing capabilities through the NextGen provider plugin.

## Overview

This Docker container provides a complete headless geospatial processing environment featuring:
- **QGIS** with Python bindings (PyQGIS)
- **SAGA GIS** compiled from source
- **SAGA NextGen Provider Plugin** for seamless integration
- **JupyterLab** for interactive analysis

## Features

### Core Components
- **QGIS 3.x** via conda-forge with full processing capabilities
- **SAGA GIS 9.3.2** compiled from source for optimal performance
- **Processing SAGA NextGen Provider** plugin for modern SAGA integration
- **JupyterLab** environment on port 8888
- **Headless operation** suitable for server deployments


## Quick Start

### Build the Container
```bash
docker build -t qgis-saga-nextgen .
```

### Run with JupyterLab
```bash
docker run -p 8888:8888 -v $(pwd)/data:/workspace qgis-saga-nextgen
```

Access JupyterLab at `http://localhost:8888`


## Container Architecture

### Directory Structure
```
/opt/conda/envs/pygile/    # QGIS installation
/opt/saga/                 # SAGA GIS binaries
/workspace/                # Working directory (mount point)
/workspace/output/         # Processing results
```

### Key Technologies
- **Base Image**: `condaforge/mambaforge:24.9.0-0`
- **QGIS**: Installed via conda-forge
- **SAGA**: Compiled from source with cmake
- **Python Environment**: Conda environment named 'pygile'


## Configuration

### SAGA NextGen Setup
The container automatically configures:
- SAGA folder path: `/opt/saga`
- Plugin activation via QgsSettings
- Algorithm discovery and parameter mapping

### Environment Variables
- `QT_QPA_PLATFORM=offscreen` for headless operation
- `QGIS_PREFIX_PATH` pointing to conda environment
- Processing provider paths

### Plugin Integration
The container solves the challenge of using SAGA NextGen in headless environments by:
- Direct provider loading: `from processing_saga_nextgen.processing.provider import SagaNextGenAlgorithmProvider`
- QgsSettings configuration for SAGA path
- Automatic algorithm discovery and parameter mapping

### Performance Optimizations
- Compiled SAGA for optimal speed
- Conda-based package management
- Efficient memory usage for large DEMs

## Troubleshooting

### Common Issues
1. **"Application path not initialized"**: Normal warning, doesn't affect functionality

### Verification
```python
# Check SAGA installation
import subprocess
subprocess.run(['/opt/saga/bin/saga_cmd', '--version'])

# Verify plugin loading
registry = QgsApplication.processingRegistry()
providers = [p.id() for p in registry.providers()]
print('sagang' in providers)  # Should return True
```

## Contributing

This container is designed for:
- Geospatial researchers requiring reproducible environments
- Organizations needing scalable terrain analysis
- Developers building geospatial processing pipelines

## License

Container configuration is open source. Underlying software licenses:
- QGIS: GPL v2
- SAGA GIS: GPL v2+
- SAGA NextGen Provider: GPL v2

## Citation

If you use this container in research, please cite:
- QGIS Development Team
- SAGA GIS Development Team
- Processing SAGA NextGen Provider (north-road/qgis-processing-saga-nextgen)

---

*Built for containerized geospatial analysis with modern SAGA integration*
