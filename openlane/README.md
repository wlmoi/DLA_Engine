# OpenLane Flow for DLA Engine (GF180MCU)

## Clarification
OpenLane is not written inside the Verilog RTL.

The flow is:
1. Write and verify RTL Verilog.
2. Run OpenLane on that RTL to do synthesis, floorplan, place and route, and signoff checks.

So yes, Verilog must be ready first, then OpenLane is executed on top of it.

## Design Folder
- Design config (OpenLane2): `openlane/designs/dla_engine_top/config.json`
- Design config (Classic): `openlane/designs/dla_engine_top/config.tcl`
- RTL source mirror used by OpenLane: `openlane/designs/dla_engine_top/src/*.v`

## RTL Structure
- Main RTL for synthesis/simulation: `rtl/*.v`
- SystemVerilog snapshot/reference: `rtl_sv/*.sv`

## PDK and Variant
This setup is pinned to:
- PDK: `gf180mcuD`

You can override the PDK from CLI if needed.

## Scripts
1. Sync RTL into OpenLane source directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\openlane\sync_sources.ps1
```

2. Run OpenLane in classic mode (flow.tcl):

```powershell
powershell -ExecutionPolicy Bypass -File .\openlane\run_openlane_docker.ps1 -Mode classic -PdkRoot "C:\\Users\\<user>\\.volare"
```

3. Run OpenLane2 mode (config.json driven):

```powershell
powershell -ExecutionPolicy Bypass -File .\openlane\run_openlane_docker.ps1 -Mode openlane2 -PdkRoot "C:\\Users\\<user>\\.volare"
```

4. Dry run (validate script setup without launching OpenLane):

```powershell
powershell -ExecutionPolicy Bypass -File .\openlane\run_openlane_docker.ps1 -Mode classic -PdkRoot "C:\\Users\\<user>\\.volare" -DryRun
```

## Notes
- Docker Desktop engine must be running before executing OpenLane scripts.
- Your PDK root must exist and be writable.
- For this project, ensure gf180mcuD is available in your PDK root (or let OpenLane/Volare fetch it).
- If your PDK root is already in `PDK_ROOT`, you can omit `-PdkRoot`.
- Keep using `gf180mcuD` for upcoming shuttle compatibility.
